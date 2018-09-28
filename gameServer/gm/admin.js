function $$(id) {
  return document.getElementById(id);
}
function AddElement(etype, parent, p, style, txt) { 
  var e = document.createElement(etype); 
  parent.appendChild(e);
  for (var k in p) { 
    if (k == 'class') e.className = p[k]; 
    else if (k == 'id') e.id = p[k]; 
    else e.setAttribute(k, p[k]); 
  } 
  for (var k in style) e.style[k] = style[k]; 
  if (txt) {
    //e.appendChild(document.createTextNode(txt));
    e.innerHTML = txt;
  }
  return e; 
}
var GMUtils=new function(){
    this.Init=function() {
        $.ajax({
          type: "GET",
          url: '../config/item.json',
          dataType:"json"
        }).done(function( data ) {
			 var select_items = $$("select_items");
          G_Items = data.sort(function(a,b){return a.itemname.localeCompare(b.itemname);});

          for(var i in G_Items) {
            var item = G_Items[i];
            var option = AddElement("option", select_items,{value:item.itemid},{},item.itemname);
          }
          this.changeItem();
        }.bind(this));
    };
    this.autoInput = function(cmd) {
      var CMD = CMDS[cmd];
      $$('fname').value=CMD.cmd;$$('input_cmd').value=CMD.param;
    };
	
    this.changeItem=function() {
		 var select_items = $$("select_items");
      var pid = select_items.options[select_items.selectedIndex].value;
      $$('input_cmd').value=$$('input_cmd').value.replace(/id":\d+/,'id":'+pid);
      $$('itemid').innerHTML = pid;
    };
    this.searchItem=function() {
      var iname = $$("input_searchitem").value;
      var soption = undefined;
      for(var i in select_items.options) {
        var option = select_items.options[i];
        var s = option.text+"";
        if(s==iname && !searcheditems[i])  {
            soption = option;
            break;
        }
        if(s.indexOf(iname)!=-1 && !searcheditems[i]) {
            soption=option;
        }
      }
      if(soption) {
        soption.selected=true;
        searcheditems[soption.index]=1;
        this.changeItem();
      }
      else {
        searcheditems = {};
      }
    };
    
    var DEBUG=$$("DEBUG");
    var G_Items = {};
    var select_items = $$("select_items");
    var searcheditems = {};
	
    var CMDS = {
        OpenServer:{
            cmd:'gm.service_open',
            param:'{}'
        },
        CloseServer:{
            cmd:'gm.service_close',
            param:'{}'
        },
		AddItem:{
            cmd:'gm.add_new_item',
            param:'{"id":10001,"num":1}'
        },
		SetLevel:{
            cmd:'gm.set_level',
            param:'{"level":20}'
        },
		CommanderSetSkillLevel:{
            cmd:'gm.commander_set_skill_level',
            param:'{"commanderid":101,"skillid":101,"skilllev":1}'
        },
      AddVipExp:{
            cmd:'gm.add_vip_exp',
            param:'{"exp":100}'
        },
      SetSatage:{
            cmd:'gm.set_stage',
            param:'{"stage":1}'
       },
      SetAlliancegirl:{
            cmd:'gm.set_alliancegirl',
            param:'{"typ":1,"value":1}'
       },
       PayItem:{
            cmd:'gm.pay_item',
            param:'{"id":1}'
       },
       setCount:{
            cmd:'gm.set_count',
            param:'{"id":1,"num":10}'
       },
       SetResourceStep:{
            cmd:'gm.set_resource_step',
            param:'{"step":1}'
       },

       
    };
}();