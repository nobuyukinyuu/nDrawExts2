' Let's see one way we can use stencil buffers to our advantage:  Making screen transitions easier to animate using a texture.
#GLFW_WINDOW_TITLE="nDrawExts2 Demo:  Transition test"
#GLFW_WINDOW_RESIZABLE=True

Import mojo
Import nDrawExts2


Function Main:Int()
	New Game()
	Return 0
End Function

Class Game Extends App
	Field bg1:Image, bg2:Image

	Field percent:Float
	Field fade:Image[12]
	Field idx:Int
	
	Field demoPlaying:Bool
	Field demoBounce:Bool 'Bounce state
	Field demoSpeed:Float = 0.010
	
	'summary:The OnCreate Method is called when mojo has been initialized and the application has been successfully created.
	Method OnCreate:Int()	
		'Set how many times per second the game should update and render itself
		SetUpdateRate(60)
		
		bg1 = LoadImage("bg1.png")
		bg2 = LoadImage("bg2.png")
		
		For Local i:Int = 0 Until fade.Length
			fade[i] = LoadImage("fades/" + i + ".png")
		Next
			
		Return 0
	End Method
	
	'summary: This method is automatically called when the application's update timer ticks. 
	Method OnUpdate:Int()

		If not demoPlaying
			If KeyDown(KEY_UP) and percent < 1
					percent = Min(1.0, percent + 0.01)
			End If 
			If KeyDown(KEY_DOWN) and percent > 0
					percent = Max(0.0, percent - 0.01)
			End If
			If KeyHit(KEY_LEFT) and idx > 0
				idx -= 1
			End If
			If KeyHit(KEY_RIGHT) and idx < fade.Length - 1
				idx += 1
			End If
			
			If KeyHit(KEY_SPACE)
				idx = 0
				'percent = 1
				demoBounce = True
				demoPlaying = True
			End If

			If MouseDown()
				percent = Clamp(MouseX() / Float(DeviceWidth()), 0.0, 1.0)
			End If

		Else  'Play a demo of all the fades.
		
			If demoBounce  'Fade up
				If percent + demoSpeed > 1
					percent =1
					doDemoBounce()
				Else
					percent += demoSpeed
				End If

			Else
				If percent - demoSpeed < 0
					percent = 0
					doDemoBounce()
				Else
					percent -= demoSpeed
				End If


			End If
		
		
		End If
	
		
		Return 0
	End Method

	Method doDemoBounce:Void()
		demoBounce = not demoBounce
		If idx + 1 = fade.Length 'End of demo.
			demoPlaying = False
		Else
			idx += 1
		End If
	End Method
		
	'summary: This method is automatically called when the application should render itself, such as when the application first starts, or following an OnUpdate call. 
	Method OnRender:Int()
		Cls()
		

		For Local y:Int = 0 To DeviceHeight() Step 200
		For Local x:Int = 0 To DeviceWidth() Step 200
			DrawImage(bg1, x, y)
			
			EnableStencil()
			ClearStencil()
			DrawToStencil(True, 1 - percent)
				DrawImage(fade[idx], 0, 0, 0, DeviceWidth() / Float(fade[idx].Width), DeviceHeight / Float(fade[idx].Height))
			DrawToStencil(False)
				DrawImage(bg2, x, y)
			DisableStencil()
		Next
		Next
		
		DrawText("Texture " + idx, 0, 0)
		DrawText(percent, 0, 16)
	End Method

End Class
