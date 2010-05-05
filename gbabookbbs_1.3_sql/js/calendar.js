/*****************
 *
 *日历程序
 *作者:marcian
 *主页:www.marcian.net
 *2007.2.10
 *特点:封装，对外暴露一个方法来调用日历,最大最小年份可调,日期可用性选择.采用DOM方式创建日历对象,页面只需调用一个js文件即可。
 *使用方法:创建日历对象,然后调用此对象的showCalendar()方法即可.
 *兼容性：IE6,Mozilla系列测试通过
 *欢迎交流.
 *自由使用，但请保留作者信息。
 *公历算法来源于网络
 *******************/

/*****************
 *为Date对象添加定制的方法
 ******************/
//获取当前时间
Date.prototype.getTheDate=function(){
	return {Y:this.getFullYear(),M:this.getMonth()+1,D:this.getDate()};
}

Date.prototype.beforeTheDate=function(Y,M,D){
	if(Y<this.getFullYear()||(Y==this.getFullYear()&&M<this.getMonth()+1)||(Y==this.getFullYear()&&M==this.getMonth()+1&&D<this.getDate()))
	{
		return true;
	}
	else
	{
		return false;
	}
}


Date.prototype.afterTheDate=function(Y,M,D){
	if(Y>this.getFullYear()||(Y==this.getFullYear()&&M>this.getMonth()+1)||(Y==this.getFullYear()&&M==this.getMonth()+1&&D>this.getDate()))
	{
		return true;
	}
	else
	{
		return false;
	}
}


Date.prototype.getThePreDate=function(dateObj,minYear){
	var M=dateObj.M;
	var Y=dateObj.Y;
	var D=dateObj.D;
	M--;
	if(M<1)
	{
		M=12;
		Y--;
	}
	if(Y<minYear)
	{
		Y=minYear;
	}
	return "{Y:"+Y+",M:"+M+",D:"+D+"}";
}


Date.prototype.getTheNextDate=function(dateObj,maxYear){
	var M=dateObj.M;
	var Y=dateObj.Y;
	var D=dateObj.D;
	M++;
	if(M>12)
	{
		M=1;
		Y++;
	}
	if(Y>maxYear)
	{
		Y=maxYear;
	}
	return "{Y:"+Y+",M:"+M+",D:"+D+"}";
}


/*****************
 *日历的构造函数
 ******************/
function MarcianCalendar(calendarObjName,display,minYear,maxYear,afterNotUsed,beforeNotUsed)
{
	/*********************************************
	*参数说明
	*calendarObjName:创建的日历对象实例名,必须
	*display:显示日历 true为显示,false为不显示.可选,默认为不显示
	*minYear:最小年份,可选,默认为1900
	*maxYear:最打年份,可选,默认为2900
	*afterNotUsed:大于当前时间的日期不可用,可选,默认为false;
	*beforeNotUsed:小于当前日期的时间不可用,可选,默认为false;
	**********************************************/

	/*属性*/
	this.calendarName=calendarObjName;//创建的日历对象实例名
	this.display=display?"block":"none";//
	this.minYear=minYear?minYear:1900;//
	this.maxYear=maxYear?maxYear:2900;//
	this.afterNotUsed=afterNotUsed?afterNotUsed:false;
	this.beforeNotUsed=beforeNotUsed?beforeNotUsed:false;
	this.calendarContainer=null;//日历容器
	this.calendarMenuContainer=null;//日历菜单容器
	this.calendarDateContainer=null;//日历日期容器
	this.calendarWeekContainer=null;//日历星期容器
	this.calendarCloseContainer=null;//关闭菜单容器
	this.weekAry=["日","一","二","三","四","五","六"];//星期数组
	this.date=new Date();//日期对象
	this.moveObjAry=new Array();//移动对象数组
	this.fillObjAry=new Array();//填充对象数组
	this.id=0;//当前ID号

	//获取指定页面元素的坐标
	this.getObjOffset=function(obj){
		var x=obj.offsetWidth;
		var y=0;
		while(obj.offsetParent)
		{
			x+=obj.offsetLeft;
			y+=obj.offsetTop;
			obj=obj.offsetParent;
		}
		return{x:x,y:y};
	}

	//移动日历
	this.moveCalendar=function(id){
		var offset=this.getObjOffset(this.$(this.moveObjAry[id]));
		this.calendarContainer.style.cssText=this.calendarContainer.getAttribute("css")+";top:"+(offset.y+20)+"px;left:"+(offset.x - 133)+"px;display:block";
		this.id=id;
	}

	//填充日期
	this.fillDate=function(dateStr){
		var fillObj=this.$(this.fillObjAry[this.id]);
		if(fillObj.type=="text")
		{
			fillObj.value=dateStr;
		}
		if(this.id<this.fillObjAry.length-1)
		{
			this.id++;
			this.moveCalendar(this.id);
		}
		else
		{
			this.calendarContainer.style.cssText=this.calendarContainer.getAttribute("css")+"display:none;";
		}
	}

	//获取页面元素的快捷方式
	this.$=function(id)
	{
		return document.getElementById(id);
	}

	//显示日历的外部调用方法
	this.showCalendar=function(showIDAry,fillIDAry){
		/******************************
		*参数说明
		*showIDAry:点击显示日历的元素的ID数组
		*fillIDAry:要填充日期数据的元素的ID数组
		******************************/
		this.moveObjAry=showIDAry;
		this.fillObjAry=fillIDAry;
		this.moveCalendar(0);
	}

	/*设置日历时间*/
	this.setDate=function(dateObj){
		if(this.calendarDateContainer.childNodes)
		{
			for(var j=this.calendarDateContainer.childNodes.length-1;j>=0;j--)
			{
				this.calendarDateContainer.removeChild(this.calendarDateContainer.childNodes[j]);
			}
		}
		var W=1;
		var Y=dateObj.Y;
		var M=dateObj.M;
		var D=dateObj.D;
		var dayAry=[31,28,31,30,31,30,31,31,30,31,30,31];
		var r=[0,3,3,6,1,4,6,2,5,0,3,5];
		var c=6;
		if(Y%400==0||(Y%4==0&&Y%100!=0))
		{
			dayAry[1]=29;
		}
		if((Y%400==0||(Y%4==0&&Y%100!=0))&&M<3)
		{
			c=5;
		}
		var y=Y%400;
		w=(y+Math.floor(y/4)-Math.floor(y/100)+r[M-1]+1+c)%7;
		//alert(w);
		var R=1;
		R=(dayAry[M-1]-7+w)%7==0?R+(dayAry[M-1]-7+w)/7:R+Math.floor((dayAry[M-1]-7+w)/7)+1;
		var start=0;
		var d=1;
		for(var i=0;i<R;i++)
		{
			var div=document.createElement("div");
			div.style.cssText="width:200px;height:23px;margin-bottom:2px;"
			for(var k=0;k<7;k++)
			{
				var p=document.createElement("p");
				p.style.cssText="width:28px;height:20px;float:left;text-align:center;padding-top:3px;margin:0px;color:#ccc;";
				if(start>=w&&d<=dayAry[M-1])
				{
					if(this.beforeNotUsed&&this.date.beforeTheDate(Y,M,d))
					{
						p.innerHTML=d;
					}
					else if(this.afterNotUsed&&this.date.afterTheDate(Y,M,d))
					{
						p.innerHTML=d;
					}
					else
					{
						p.innerHTML="<a href='javascript:"+this.calendarName+".fillDate(\""+Y+"-"+M+"-"+d+"\");void(0);' class='bluelink'>"+d+"</a>";
					}
					d++;
				}
				start>w?start=w:start++;
				div.appendChild(p);
			}
		  this.calendarDateContainer.appendChild(div);
		}
	}

	/*设置日历控制菜单*/
	this.setMenu=function(dateObj){
		this.calendarMenuContainer.innerHTML="<a href='javascript:"+this.calendarName+".setMenu("+this.date.getThePreDate(dateObj,this.minYear)+");void(0)' class='bluelink'>上月</a>　"+dateObj.Y+"-"+(dateObj.M>9?dateObj.M:"0"+dateObj.M)+"　<a href='javascript:"+this.calendarName+".setMenu("+this.date.getTheNextDate(dateObj,this.maxYear)+");void(0)' class='bluelink'>下月</a>";
		this.setDate(dateObj);
	}

	/*初始化*/
	this.initial=function(){
		this.calendarContainer=document.createElement("div");
		this.calendarContainer.style.cssText="position:absolute;top:0px;left:0px;width:200px;border:1px solid #666; padding: 1px;background:#fff;font:12px Arial;margin-bottom:1px;display:"+this.display+";";
		this.calendarContainer.setAttribute("css",this.calendarContainer.style.cssText);
		this.calendarMenuContainer=document.createElement("div");
		this.calendarMenuContainer.style.cssText="width:200px;height:20px;background:#efefef;color:#666;text-align:center;";
		this.calendarWeekContainer=document.createElement("div");
		this.calendarWeekContainer.style.cssText="width:200px;height:20px;margin-bottom:1px;";
		for(i=0;i<7;i++)
		{
			var p=document.createElement("p");
			p.style.cssText="width:28px;height:20px;float:left;text-align:center;padding-top:3px;border-bottom:1px solid #ccc;margin:0px;";
			p.innerHTML=this.weekAry[i];
			this.calendarWeekContainer.appendChild(p);
		}
		this.calendarDateContainer=document.createElement("div");
		this.calendarDateContainer.style.cssText="width:200px;";
		this.calendarCloseContainer=document.createElement("div");
		this.calendarCloseContainer.style.cssText=this.calendarMenuContainer.style.cssText;
		this.calendarCloseContainer.innerHTML="<a href='javascript:"+this.calendarName+".calendarContainer.style.display=\"none\";void(0);' style=\"display: block; height: 20px;\">关闭日历</a>";
		this.calendarContainer.appendChild(this.calendarMenuContainer);
		this.calendarContainer.appendChild(this.calendarWeekContainer); 
		this.calendarContainer.appendChild(this.calendarDateContainer); 
		this.calendarContainer.appendChild(this.calendarCloseContainer);
		document.body.appendChild(this.calendarContainer);
		this.setMenu(this.date.getTheDate());
	}

	//检查输入的年参数是否符合要求.
	this.checkYear=function(){
		if(!this.minYear.toString().match(/\d\d\d\d/))
		{
			alert("最低年份输入不正确，重新输入");
		}
		else if(!this.maxYear.toString().match(/\d\d\d\d/))
		{
			alert("最高年份输入不正确，重新输入");
		}
		else if(eval("0+"+this.maxYear)<=eval("0+"+this.minYear))
		{
			alert("最高年份必须大于最低年份,重新输入");
		}
		else if(eval("0+"+this.maxYear)<this.date.getFullYear())
		{
			alert("最高年份必须大于或者等于当前年份");
		}
		else
		{
		  this.initial();
		}
	}

	this.checkYear();
}
calendar=new MarcianCalendar("calendar",false,"","",false,true);