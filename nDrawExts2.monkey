'nDrawExts2, by Nobuyuki (nobu@subsoap.com).  No warranties implied, use at your own risk
'Last update:  29 Dec 2013

'Notes/Issues:
'1:  This doesn't work on HTML5, flash, or XNA.  Only pure ogl targets.
'
'2:  You can't write pixels OnCreate().  This will cause a Memory Access Violation.
'    You'll pull your hair out trying to figure out why.  Just don't do it.
'3:  LoadImageData appears to load stuff in ABGR8888. WritePixels expects ARGB8888.
'    Endianess in MY Monkey?  It's more likely than you think. OGL is big-endian.
'4:  On glfw, sometimes the stencil buffer is not initialized.  You should call
'      GlfwGame.GetGlfwGame().SetGlfwWindow( width,height,8,8,8,0,0,8,False )
'    at the top of OnCreate() to make sure stencil buffer works on all systems.

Import mojo
Import opengl.gles11

  Private
	Global _ndx_alpha_threshold:Float = 0.5  'For alpha pass/fail tests on stencil, certain blend modes
  
  Public

'Consts
	Const BLEND_ALPHA = 0
	Const BLEND_ADD = 1
	Const BLEND_SOFT_ADD = 2
	Const BLEND_MULTIPLY = 3
	Const BLEND_INVERT = 4

	Const LOGICOP_DISABLE = 0
	Const LOGICOP_COPY_INVERTED = 1
	Const LOGICOP_INVERT = 2
	Const LOGICOP_AND = 3
	Const LOGICOP_NAND = 4
	Const LOGICOP_OR = 5
	Const LOGICOP_NOR = 6
	Const LOGICOP_XOR = 7
	Const LOGICOP_EQUIVALENT = 8
	Const LOGICOP_AND_REVERSE = 9
	Const LOGICOP_AND_INVERTED = 10
	Const LOGICOP_OR_REVERSE = 11
	Const LOGICOP_OR_INVERTED = 12

'Functions	
	Function SetBlend2:Int(blend:Int)
		Flush()
		
		#If LANG="java"
			'We need to trick mojo into enabling GL_BLEND by falling back on SetBlend().
			SetBlend(Sgn(blend))
		#EndIf 
		
		Select blend
		Case BLEND_ADD
			glBlendFunc(GL_ONE, GL_ONE)
		Case BLEND_SOFT_ADD
			glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ONE)
		Case BLEND_MULTIPLY
			glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA)
		Case BLEND_INVERT
			glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA)
		Default
			glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
		End Select

		Return 0		
	End Function
	
	Function SetLogicOp:Int(logicop:Int)
		Flush()
		
		
		If (logicop > 0) And (glIsEnabled(GL_COLOR_LOGIC_OP) = False)
			glEnable(GL_COLOR_LOGIC_OP)
			glAlphaFunc(GL_GREATER, _ndx_alpha_threshold)
			glEnable(GL_ALPHA_TEST)
		End If
		
		Select logicop
		Case LOGICOP_COPY_INVERTED
			glLogicOp(GL_COPY_INVERTED)
		Case LOGICOP_INVERT
			glLogicOp(GL_INVERT)
		Case LOGICOP_AND
			glLogicOp(GL_AND)
		Case LOGICOP_NAND
			glLogicOp(GL_NAND)
		Case LOGICOP_OR
			glLogicOp(GL_OR)
		Case LOGICOP_NOR
			glLogicOp(GL_NOR)
		Case LOGICOP_XOR
			glLogicOp(GL_XOR)
		Case LOGICOP_EQUIVALENT
			glLogicOp(GL_EQUIV)
		Case LOGICOP_AND_REVERSE
			glLogicOp(GL_AND_REVERSE)
		Case LOGICOP_AND_INVERTED
			glLogicOp(GL_AND_INVERTED)
		Case LOGICOP_OR_REVERSE
			glLogicOp(GL_OR_REVERSE)
		Case LOGICOP_OR_INVERTED
			glLogicOp(GL_OR_INVERTED)
		Default
			If glIsEnabled(GL_COLOR_LOGIC_OP) = True Then
				glDisable(GL_COLOR_LOGIC_OP)
				glAlphaFunc(GL_ALWAYS, 0)
				glDisable(GL_ALPHA_TEST)
			End If
		End Select
		
		Return 0
	End Function

	'Summary:  Gets the threshold value		
	Function GetAlphaThreshold:Float()
		Return _ndx_alpha_threshold
	End Function
	
	Function SetAlphaThreshold:Void(threshold:Float)
		_ndx_alpha_threshold = threshold
	End Function
		
	Function EnableStencil:Void()
		Flush()
		glClearStencil(0)
		glEnable(GL_STENCIL_TEST)
	End Function
		
	Function DisableStencil:Void()
		Flush()
		glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
		glDisable(GL_STENCIL_TEST);
	End Function
		
	Function ClearStencil:Void()
		glClear(GL_STENCIL_BUFFER_BIT)
	End Function
		
	Function DrawToStencil:Void(enabled:Bool)
		If enabled
			glAlphaFunc(GL_GREATER, _ndx_alpha_threshold)
			glEnable(GL_ALPHA_TEST)
			
			glColorMask(False, False, False, False)
		    glStencilFunc(GL_ALWAYS, 1, 1)
    		glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE)
		Else
			Flush()
			glAlphaFunc(GL_ALWAYS, 0)
			glDisable(GL_ALPHA_TEST)

			glColorMask(True, True, True, True)
		    glStencilFunc(GL_EQUAL, 1, 1)
			glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP)
		End If
		
	End Function


Class PixelArray
	'Summary:  Loads an ARGB image into an array of ints.
	Function Get:Int[] (path:String, info:Int[])
		Local data:Int[]
		Local db:DataBuffer = LoadImageData("monkey://data/" + path, info)
			
		'Local timeSpent:Int = Millisecs()
		
		'Copy the data buffer into an array.
		 data = data.Resize(db.Length / 4)  '32-bits = 4 bytes
	
		'We need to swap bytes of R and B channels around.
		For Local i:Int = 0 Until db.Length Step 4
			Local j:Int = db.PeekInt(i)
			
			data[i / 4] = (j & $ff000000) | ((j & $00ff0000) Shr 16) | (j & $0000ff00) | ((j & $000000ff) Shl 16)
		Next
	
		'Print "Operation took " + (Millisecs() -timeSpent) + "ms"
		
		Return data
	End Function
	
	'Summary:  Loads a section of an ARGB image into an array of ints.
	Function Get:Int[] (path:String, startX:Int, startY:Int, w:Int, h:Int)
		Local data:Int[]
		Local info:Int[2]
		Local db:DataBuffer = LoadImageData("monkey://data/" + path, info)
			
		'Local timeSpent:Int = Millisecs()
		
		'Copy the data buffer into an array.
		 data = data.Resize(w * h)
	
		'We need to swap bytes of R and B channels around.
		For Local y:Int = 0 Until h
			For Local x:Int = 0 Until w
				Local j:Int = db.PeekInt( ( (startY + y) * info[0] + (startX + x)) * 4)
				
				data[y * w + x] = (j & $ff000000) | ( (j & $00ff0000) Shr 16) | (j & $0000ff00) | ( (j & $000000ff) Shl 16)
			Next
		Next
		
		'Print "Operation took " + (Millisecs() -timeSpent) + "ms"
		
		Return data
	End Function

	'Summary:  Crops a 1d pixel array to the specified rectangle.  Width of image in data must be specified.	
	Function Crop:Int[] (pixeldata:Int[], strideWidth:Int, startX:Int, startY:Int, w:Int, h:Int)
		Local output:Int[w * h]
	
		For Local y:Int = 0 Until h
			For Local x:Int = 0 Until w
				output[y * w + x] = pixeldata[ (y + startY) * strideWidth + (x + startX)]
			Next
		Next
		
		Return output
	End Function

	'Summary:  Grabs a color from an ARGB value and returns an array [A,R,G,B].	
	Function GetARGB:Int[] (argb:Int)
		Local out:Int[4]
		out[3] = (argb) & $FF
		out[2] = (argb Shr 8) & $FF
		out[1] = (argb shr 16) & $FF
		out[0] = (argb shr 24) & $FF
		
		Return out
	End Function
	
	'Summary:  Returns an ARGB value from the colors specified.
	Function ToARGB:Int(a, r, g, b)
		'Return (r Shl 24) + (g Shl 16) + (b Shl 8) + a
		
		Local color:Int
		color |= (a & $FF) Shl 24
		color |= (r & $FF) Shl 16
		color |= (g & $FF) Shl 8
		color |= (b & $FF)
		Return color
	End Function
	
	Function ToARGB:Int(color:Int[])
		Local out:Int
		out |= (color[0] & $FF) Shl 24
		out |= (color[1] & $FF) Shl 16
		out |= (color[2] & $FF) Shl 8
		out |= (color[3] & $FF)
		Return color		
	End Function
End Class

	
	
'There's probably some pure monkey way around this....
Private
Extern
#If LANG="cpp"
	'Flushes all pending draw operations to their respective buffers.  Or something.
	Function Flush:Void() = "bb_graphics_device->Flush"
#ElseIf LANG="java"
	Function Flush:Void() = "bb_graphics.g_device.Flush"
#EndIf