var talents = {};

function debug()
{
	$.Msg("Debug!");
	var panelLeft = $.CreatePanel("Panel", $("#TalentsLeft"), "");
	panelLeft.BLoadLayoutSnippet("Talent");
	var panelRight = $.CreatePanel("Panel", $("#TalentsRight"), "");
	panelRight.BLoadLayoutSnippet("Talent");
}

function LoadTalent(side, name, description, prerequisites, image)
{
	if (side == "left")
	{
		var panel = $.CreatePanel("Panel", $("#TalentsLeft"), "");
	}
	else
	{
		var panel = $.CreatePanel("Panel", $("#TalentsRight"), "");
	}
	panel.BLoadLayoutSnippet("Talent");
	panel.FindChildTraverse("TalentName").text = name;
	panel.FindChildTraverse("TalentDescription").text = description;
	panel.FindChildTraverse("TalentPrerequisites").text = prerequisites;
	panel.FindChildTraverse("Image").SetImage("file://{resources}/images/custom_game/talent_tree/" + image + ".png");
	
	return panel;
}
 
function ToggleTree()
{
	$("#TalentWindow").ToggleClass("window_show");
}

/* Event Listeners */
function OnTalentLoad(dat)
{
	var talent = LoadTalent(dat.side, dat.name, dat.desc, dat.prerequisites, dat.image)
	talent.tag = dat.id;
	talents[dat.id] = talent;
}

function OnTalentLearnt()
{
	for (var x in talents)
	{
		talent = talents[x];
		if (talent.tag == dat.id)
		{
			SetTalentLearnt(talent);
			break;
		}
	}
}

function SubscribeToGameEvents()
{
	GameEvents.Subscribe("talent_tree_load_talent", OnTalentLoad);
//	GameEvents.Subscribe("talent_tree_learn_talent", OnTalentLearnt);
//	GameEvents.Subscribe("talent_tree_prerequisite_met", OnTalentUpdate);
}

SubscribeToGameEvents();