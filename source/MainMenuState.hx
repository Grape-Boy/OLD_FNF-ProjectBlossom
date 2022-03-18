package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var galleryID:Int = 0;
	var galleryY:Float = 0; // janky ass sprite, need to do weird stuff to keep it normal
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'gallery',
		'credits',
		#if !switch 'donate', #end
		'options',
	];

	var optionColors:Array<Int> = [
		0xFF9664F5,
		0xFFFF4B4B,
		#if MODS_ALLOWED 0xFF665AFF, #end
		#if ACHIEVEMENTS_ALLOWED 0xFF964BFF, #end
		0xFFFFFB7D,
		0xFF4BFF73,
		#if !switch 0xFFFFD732, #end
		0xFF96FFFF,
	];

	var optionPositions:Map<String, Array<Int>> = [
		'story_mode' => [85, 0],
		'freeplay' => [65, 0],
		#if MODS_ALLOWED 'mods' => [20, 0], #end
		#if ACHIEVEMENTS_ALLOWED 'awards' => [60, 0], #end
		'gallery' => [0, 0],
		'credits' => [80, 0],
		#if !switch 'donate' => [60, 0], #end
		'options' => [50, 0],
	];

	//var magenta:FlxSprite;
	var camZooming:Bool = false;
	var defaultCamZoom:Float = FlxG.camera.initialZoom;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var zoomTween:FlxTween;

	var bg:FlxSprite;
	var bgColorTween:FlxTween;
	
	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		var initialCamZoom:Float = defaultCamZoom + 0.5;

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.camera.zoom = initialCamZoom;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		//var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1); = useless :((
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0); // no scrolling!! also i DONT think it defaults to 0, 0 !!
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.color = 0xFF4b4b4b;
		add(bg);
		
		// idk what this means but it makes graphics
		var darkArea = new FlxSprite();
		darkArea.makeGraphic(200, 2000, FlxColor.BLACK);
		darkArea.x = -100;
		darkArea.scrollFactor.set(0, 0);
		darkArea.updateHitbox();
		add(darkArea);

		var outlineCheckers:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menucheckers/left_checkers'));
		outlineCheckers.scrollFactor.set(0, 0);
		//outlineCheckers.screenCenter(Y);
		outlineCheckers.x -= 500;
		outlineCheckers.antialiasing = ClientPrefs.globalAntialiasing;
		outlineCheckers.updateHitbox();

		add(outlineCheckers);

		FlxTween.tween(
			outlineCheckers,
			{ x: 0},
			0.5,
			{ ease: FlxEase.backOut}
		);
		
		FlxTween.tween(
			FlxG.camera,
			{zoom: defaultCamZoom},
			1,
			{ ease: FlxEase.sineIn}
		);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		add(camFollow);
		add(camFollowPos);
		/*
		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		*/
		
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);

			menuItem.scale.x = scale;
			menuItem.scale.y = scale;

			menuItem.x -= 250;
			menuItem.y += 150;

			menuItem.alpha = 0;

			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);

			menuItem.antialiasing = ClientPrefs.globalAntialiasing;

			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');

			menuItem.ID = i;

			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			add(menuItem);

			if(optionShit[i] == 'gallery')
			{
				galleryID = i;
				menuItem.y -= 20;
				galleryY = menuItem.y;
			};
			
			if(curSelected == i)
			{
				FlxTween.tween(
					menuItem,
					{ x: optionPositions[optionShit[i]][0]}, // hard
					2,
					{ ease: FlxEase.backOut}
				);
			}

			FlxTween.tween(
				menuItem,
				{ alpha: 1},
				1.5,
				{ ease: FlxEase.sineOut}
			);

			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				if(zoomTween != null) zoomTween.cancel();

				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					if(ClientPrefs.camZooms) {
						FlxG.camera.zoom += 0.15;

						zoomTween = FlxTween.tween(
							FlxG.camera,
							{zoom: defaultCamZoom},
							1,
							{ ease: FlxEase.sineOut}
						);
					}

					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'gallery':
										MusicBeatState.switchState(new GalleryState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
		/*
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
		*/
	}

	function changeItem(huh:Int = 0)
	{
		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.05;

			if(!camZooming) { 
				zoomTween = FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.125);
			};
		};

		//var oldSelected:Int = curSelected;
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		var durationTime:Float = 1;
		if(ClientPrefs.flashing)
			durationTime = 0.25;


		if(bgColorTween != null)
			bgColorTween.cancel();

		bgColorTween = FlxTween.color(
			bg,
			durationTime,
			bg.color,
			optionColors[curSelected],
			{ ease: FlxEase.sineIn }
		);

		function resetOtherPositions(ID:Int = 0)
		{
			menuItems.forEach(function(spr:FlxSprite)
			{
				if(spr.ID != ID)
					spr.x = 0;
				if(spr.ID != galleryID)
					menuItems.members[galleryID].y = galleryY;
			});
		};

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');

				var i:Int = spr.ID;
				spr.x = optionPositions[optionShit[i]][0]; // complex coding!
				resetOtherPositions(spr.ID);

				/*
				switch (optionShit[spr.ID]) {
					case 'story_mode':
						spr.x = 85;
						resetOtherPositions(spr.ID);
					case 'freeplay':
						spr.x = 65;
						resetOtherPositions(spr.ID);
					case 'mods':
						spr.x = 20;
						resetOtherPositions(spr.ID);
					case 'awards':
						spr.x = 60;
						resetOtherPositions(spr.ID);
					case 'gallery':
						spr.y = galleryY - 20;
						resetOtherPositions(spr.ID);
					case 'credits':
						spr.x = 80;
						resetOtherPositions(spr.ID);
					case 'donate':
						spr.x = 60;
						resetOtherPositions(spr.ID);
					case 'options':
						spr.x = 50;
						resetOtherPositions(spr.ID);
				};
				*/

				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
