Import mojo
Import nDrawExts2

Alias SetBlend = SetBlend2 'Override SetBlend

Function Main:Int()
	New Game()
End Function

Class Game Extends App
	Field state:Int  'Which demo should we be showing?

	'First demo
	Field bg:Image, fg:Image  'Monkey face, bubbles
	Field b1:Int = BLEND_MULTIPLY   'Blend mode
	Field lop:Int  'Logic op mode
	Field swap:Int = 1 'swaps color wheels, like a bool
	
	Field blendNames:String[] =["None (Alpha blending)", "Additive", "Soft Add", "Multiply", "Inverse", "(Undefined)"]
	Field lopNames:String[] =["None", "Invert", "Invert underlying", "And", "Nand", "Or", "Nor", "Xor", "Equivalents",
							   "And (Reverse)", "And (Inverted)", "Or (Reverse)", "Or (Inverted)", "(Undefined)"]
	
	Field theta:Float, theta2:Float

	
	'Second demo	
	Field bg2:Image  'Test image
	Field fg2:Image[4]  'Flames
	Field imgAlign:Image  'Alignment image, for testing slices
	Field imgSlice:Image, imgSlice2:Image  'Testing slice functions
	
	Field FirstLoad:Bool = True
		
	Method OnCreate()
		bg = LoadImage("monkey.png",, Image.MidHandle)
		fg = LoadImage("bubble.png",, Image.MidHandle)
		
		bg2 = LoadImage("test_texture.png",, Image.MidHandle)
		fg2[0] = LoadImage("fireball.png", 4, Image.MidHandle)
		
		SetUpdateRate 60
	End Method
	
	Method OnUpdate()
		
		Select state
		Case 0	'Standard demo
			Local input:Int = GetChar()
	
			'Set blend mode
			If input >= 48 And input < 58 Then
				input -= 48
				 b1 = input
			End If
			
			'Set color wheels
			If KeyHit(KEY_SPACE) Or MouseHit(MOUSE_RIGHT) Or KeyHit(KEY_MENU)
				swap = 1 - swap
			End If
			
			'Cycle blends
			If MouseHit And ( Not TouchHit(1))
				b1 += 1
				If b1 > 4 Then b1 = 0
			End If
				
			'LogicOp cycler
			If MouseHit(MOUSE_MIDDLE) or KeyHit(KEY_SHIFT) or TouchHit(1)
				If lop >= 12 Then lop = 0 Else lop += 1
			End If
	
					
			If KeyHit(KEY_ESCAPE) Then Error("")
		Case 1
			If FirstLoad
				Local size:Int[2]
				Local data:Int[] = PixelArray.Get("align.png", size)
				
				'Let's load the image using the data array.
				imgAlign = CreateImage(size[0], size[1])
				'Write pixels
				imgAlign.WritePixels(data, 0, 0, size[0], size[1])
				
				'Now let's make one by cropping the center image out of the old array.
				data = PixelArray.Crop(data, size[0], size[0] / 4, size[1] / 4, size[0] / 2, size[1] / 2)
				imgSlice = CreateImage(size[0] / 2, size[1] / 2)
				imgSlice.WritePixels(data, 0, 0, size[0] / 2, size[1] / 2)

				'Okay, but can we do that without parsing the entire image first?
				data = PixelArray.Get("align.png", 8, 8, 48, 48)
				imgSlice2 = CreateImage(48, 48)
				imgSlice2.WritePixels(data, 0, 0, 48, 48)

				
				'Okay that's cool, but how about we some practical usage?
				data = PixelArray.Get("fireball.png", size)
				For Local i:Int = 1 Until fg2.Length
					Local tmp:Image = CreateImage(size[0], size[1])
					For Local j:Int = 0 Until data.Length
						Local color:Int[] = PixelArray.GetARGB(data[j])

						'Shift the hue.
						Local newColor:Float[] = RGBtoHSL(color[1], color[2], color[3])
						newColor[0] = Cycle(newColor[0] + (i / 12.0), 0, 1)
						
												
						data[j] = HSLtoRGB(newColor[0], newColor[1], newColor[2], color[0])
					Next
					tmp.WritePixels(data, 0, 0, size[0], size[1])
					Print i
					fg2[i] = tmp.GrabImage(0, 0, size[0] / 4, size[1], 4, Image.MidHandle)  'Cruddy hack to re-add frames
				Next
												
				FirstLoad = False
			End If
		End Select

		'Prev/Next demo
		If KeyHit(KEY_LEFT)
			state -= 1
			If state < 0 Then state = 0
		End If
		If KeyHit(KEY_RIGHT) or TouchHit(2)
			state = 1 - state
		End If
	
		'Move the animated things around
		theta += 1
		If theta >= 360 Then theta -= 360
		theta2 += 3.231
		If theta2 >= 360 Then theta2 -= 360
		
			
	End Method
	
	Method OnRender()
		Select state
		Case 0 'Standard demo
			Cls(255 * swap, 255 * swap, 255 * swap)
			ClearStencil()
	
			EnableStencil()   'Everything between EnableStencil and DisableStencil is drawn inside the stencil.
			'We use DrawToStencil(True) to draw directly to the stencil. This is our last chance to set alpha threshold.
			DrawToStencil(True)
				DrawCircle(MouseX, MouseY, 124)  'Clip it to a circle around the cursor.
			DrawToStencil(False) 'Set it back to false to enable normal drawing again.
	
			'Draw checkerboard. This will be clipped to the stencil.
			For Local y:Int = 0 To DeviceHeight + 18 Step 36
				For Local x:Int = 0 To DeviceWidth + 18 Step 36
				SetColor(128, 128, 128); SetAlpha(0.5)
					'DrawCircle(x, y, 9)
					DrawPoly([x + 18.0, y, x, y - 18.0, x - 18.0, y, x, y + 18.0])
				SetColor(255, 255, 255); SetAlpha(1)
				Next
			Next
	
			DisableStencil()  'Stop the stencil operation
			
			'Draw monkey
			DrawImage(bg, DeviceWidth() / 2 + Sin(theta2) * 32, DeviceHeight() / 2 + Sin(theta) * 64)
	
			'Draw venn diagram
	 		 SetBlend(b1)
			QColor(1 + swap * 3)
			DrawCircle(DeviceWidth() / 2 + Sin(theta) * 64, DeviceHeight() / 2 + Cos(theta) * 64, 128)
			QColor(2 + swap * 3)
			DrawCircle(DeviceWidth() / 2 + Sin(theta + 120) * 64, DeviceHeight() / 2 + Cos(theta + 120) * 64, 128)
			QColor(3 + swap * 3)
			DrawCircle(DeviceWidth() / 2 + Sin(theta + 240) * 64, DeviceHeight() / 2 + Cos(theta + 240) * 64, 128)
			QColor(7)
			 SetBlend(0)
	
			 
			 'Draw Some text stuff -- inverted if the bg colors have been swapped.		 
			 SetAlphaThreshold(0)  'Forces a draw of the entire surface
			 SetLogicOp(LOGICOP_COPY_INVERTED And swap)
			 DrawText("Number keys/LMB adjust the blend mode.", 8, 8)
			 DrawText("Press SPACEBAR, RMB, or Menu key to toggle RGB/CMY colors.", 8, 20)
			 DrawText("Press MMB, Shift, or 2 touches to adjust Logic ops.", 8, 32)
			 			 
			 DrawText("Next Demo: R Arrow / 3 Touches", DeviceWidth() -8, DeviceHeight() -8, 1, 1)
			 
			 SetColor(255, 255, 255); SetBlend(0)
			 Local swapMode:String
			 If swap = 0 Then swapMode = "RGB" Else swapMode = "CMY"
			 DrawText("Colors: " + swapMode, 8, DeviceHeight() -36,, 1)
			 DrawText("LogicOp mode: " + lop + ", " + lopNames[lop], 8, DeviceHeight() -20,, 1)
			 DrawText("Blend mode: " + b1 + ", " + blendNames[Min(5, b1)], 8, DeviceHeight() -8,, 1)
		 	 SetLogicOp(LOGICOP_DISABLE)  'Re-setups the logicOps for next time
			 	
			 
			 'Set the logic op and alpha cull to whatever the user has selected
			SetAlphaThreshold(0.5)
			SetLogicOp(lop)
				DrawImage(fg, MouseX(), MouseY(), 0, 0.5, 0.5)
				'DrawCircle(128, 128, 128)
			SetLogicOp(LOGICOP_DISABLE)
	
			SetBlend(0)
			

		Case 1
			Cls(0, 0, 64)

			'Background stripes
			SetAlpha(0.1)
			For Local i:Int = -32 To DeviceHeight() +32 Step 32
				DrawRect(0, i + (1000 - Millisecs() Mod 1000) * 0.032, DeviceWidth(), 16)
			Next
			SetAlpha(1)
			
			'Draw test image bg
			DrawImage(bg2, 0, DeviceHeight() / 2, 0, 0.5, 0.5)
			DrawImage(bg2, DeviceWidth(), DeviceHeight() / 2, 0, 0.5, 0.5)
			
			DrawText("PixelArray test.  Demonstrating slicing images and alpha image manipulation.", 8, 8)
			DrawText("Touch 3 times or press l/r arrow to go back.", 8, 24)
			

			If FirstLoad = False  'Gotta wait for the images to load before trying to blit them.
				'Draw slices
				DrawImage(imgAlign, DeviceWidth() / 2 + Sin(theta2) * 32, DeviceHeight() / 2 + Sin(theta) * 64)
				DrawImage(imgSlice, DeviceWidth() / 2 + Sin(theta2 + 240) * 32, DeviceHeight() / 2 + Sin(theta + 240) * 64)
				DrawImage(imgSlice2, DeviceWidth() / 2 + Sin(theta2 + 120) * 32, DeviceHeight() / 2 + Sin(theta + 120) * 64)
				
				'Draw hue-altered flames
				For Local i:Int = 0 To 3
					DrawImage(fg2[i], i * (DeviceWidth() - (DeviceWidth() / 10)) / 3 + DeviceWidth() / 20, 420,
							  (Millisecs() +i * 4) Mod 16 / 4)
				Next				
			End If

			
		End Select
	End Method

End Class

'Below are helper functions.
'=======================================================================================

'Summary:  Returns a color for an int, much like qbasic's COLOR statement
Function QColor:Void(color:Int)
	Select color
		Case 0 'Black
		SetColor(0, 0, 0)
		Case 1 'Red
		SetColor(192, 0, 0)
		Case 2 'Green
		SetColor(0, 192, 0)
		Case 3 'Blue
		SetColor(0, 0, 192)
		Case 4 'Cyan
		SetColor(0, 192, 192)
		Case 5 'Magenta
		SetColor(192, 0, 192)
		Case 6 'Yellow
		SetColor(192, 192, 0)
		Case 7 'Gray
		SetColor(128, 128, 128)
		Case 8 'White
		SetColor(192, 192, 192)
	End Select
End Function




' colour conversions (hsl is range 0-1, return is RGB as a single int)
' Monkey conversion of http://www.geekymonkey.com/Programming/CSharp/RGB2HSL_HSL2RGB.htm
' shamelessly stolen and altered from the Diddy framework......
Function HSLtoRGB:Int(hue:Float, saturation:Float, luminance:Float, alpha:int)
	Local r:Float = luminance, g:Float = luminance, b:Float = luminance
	Local v:Float = 0
	If luminance <= 0.5 Then
		v = luminance * (1.0 + saturation)
	Else
		v = luminance + saturation - luminance * saturation
	End
	If v > 0 Then
		Local m:Float = luminance + luminance - v
		Local sv:Float = (v - m) / v
		hue *= 6
		Local sextant:Int = Int(hue)
		Local fract:Float = hue - sextant
		Local vsf:Float = v * sv * fract
		Local mid1:Float = m + vsf
		Local mid2:Float = v - vsf
		
		Select sextant
			Case 0
				r = v
				g = mid1
				b = m

			Case 1
				r = mid2
				g = v
				b = m

			Case 2
				r = m
				g = v
				b = mid1

			Case 3
				r = m
				g = mid2
				b = v

			Case 4
				r = mid1
				g = m
				b = v
			
			Case 5
				r = v
				g = m
				b = mid2
		End
	End
		
	Return (alpha Shl 24) | (Int(r * 255) Shl 16) | (Int(g * 255) Shl 8) | (Int(b * 255) Shl 0)
End

' colour conversions (rgb is 0-255, return is a float array, reusing the hslvals array if it was big enough)
' Monkey conversion of http://www.geekymonkey.com/Programming/CSharp/RGB2HSL_HSL2RGB.htm
Function RGBtoHSL:Float[] (red:Int, green:Int, blue:Int)
	Local hslvals:Float[3]
	Local r:Float = red/255.0, g:Float = green/255.0, b:Float = blue/255.0
	hslvals[0] = 0
	hslvals[1] = 0
	hslvals[2] = 0
	
	' calculate luminance
	Local v:Float = Max(Max(r,g),b)
	Local m:Float = Min(Min(r,g),b)
	hslvals[2] = (m + v) / 2.0
	' die if it's black
	If hslvals[2] <= 0 Then Return hslvals
	
	' precalculate saturation
	Local vm:Float = v - m
	hslvals[1] = vm
	' die if it's grey
	If hslvals[1] <= 0 Then Return hslvals
	
	' finish saturation
	If hslvals[2] <= 0.5 Then
		hslvals[1] /= v + m
	Else
		hslvals[1] /= 2 - v - m
	End
	
	Local r2:Float = (v - r) / vm
	Local g2:Float = (v - g) / vm
	Local b2:Float = (v - b) / vm
	If r = v Then
		If g = m Then hslvals[0] = 5 + b2 Else hslvals[0] = 1 - g2
	Elseif g = v Then
		If b = m Then hslvals[0] = 1 + r2 Else hslvals[0] = 3 - b2
	Else
		If r = m Then hslvals[0] = 3 + g2 Else hslvals[0] = 5 - r2
	End
	hslvals[0] /= 6.0
	
	Return hslvals
End

'Summary: Cycles a value until it's within the range specified, from first(inclusive) to last(exclusive).
Function Cycle:Float(value:Float, first:Float, last:Float)
	Local amt:Float = last - first  'The amount to cycle values outside the range
	
	While value >= last
		value -= amt
	Wend
	
	While value < first
		value += amt
	Wend
	
	Return value
End Function
