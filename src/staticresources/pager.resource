var pageSize = 1;
var reqObj;
var grandParent;
makePager = function(page){
	var show_per_page = pageSize;
	var number_of_items = $(reqObj).size();
	var number_of_pages = Math.ceil(number_of_items / show_per_page);
	var number_of_pages_todisplay = 5;
	var navigation_html = '<center>';
	var current_page = page;
	//var current_link = (number_of_pages_todisplay >= current_page ? 1 : number_of_pages_todisplay + 1);
	var current_link = current_page;
	if (current_page > 1)
		current_link = current_page;
	if (current_link != 1) navigation_html += "<a class='nextbutton' href=\"javascript:first();\">< Start&nbsp;</a>&nbsp;<a class='nextbutton' href=\"javascript:previous();\">< Prev&nbsp;</a>&nbsp;";
	if (current_link == number_of_pages - 1) current_link = current_link - 3;
	else if (current_link == number_of_pages) current_link = current_link - 4;
	else if (current_link > 2) current_link = current_link - 2;
	else current_link = 1;
	var pages = number_of_pages_todisplay;
	while (pages != 0) {
		if (number_of_pages < current_link) { break; }
		if (current_link >= 1)
			navigation_html += "<a class='" + ((current_link == current_page) ? "currentPageButton" : "numericButton") + "' href=\"javascript:showPage(" + current_link + ","+pageSize+",'"+reqObj+"','"+grandParent+"')\" longdesc='" + current_link + "'>" + (current_link) + "</a>&nbsp;";
		current_link++;
		pages--;
	}
	if (number_of_pages > current_page){
		navigation_html += "<a class='nextbutton' href=\"javascript:next()\">Next ></a>&nbsp;<a class='nextbutton' href=\"javascript:last(" + number_of_pages + ");\">Last ></a>";
	}
	navigation_html += '</center>';
			$(grandParent).find('.page_navigation').html(navigation_html);
}

showPage = function (page,per_page,obj,gParent) {
	pageSize = per_page;
	reqObj = obj;
    grandParent = gParent;
	$(reqObj).hide();
	$(grandParent).find('.current_page').val(page);
	$(reqObj).each(function (n) {
		if (n >= pageSize * (page - 1) && n < pageSize * page)
			$(this).show();
	});
	makePager(page);
}
next = function () {
	new_page = parseInt($(grandParent).find('.current_page').val()) + 1;
	showPage(new_page,pageSize,reqObj,grandParent);
}
last = function (number_of_pages) {
	new_page = number_of_pages;
	$(grandParent).find('.current_page').val(new_page);
	showPage(new_page,pageSize,reqObj,grandParent);
}
first = function () {
	var new_page = "1";
	$(grandParent).find('.current_page').val(new_page);
	showPage(new_page,pageSize,reqObj,grandParent);
}
previous = function () {
	new_page = parseInt($(grandParent).find('.current_page').val()) - 1;
	$(grandParent).find('.current_page').val(new_page);
	showPage(new_page,pageSize,reqObj,grandParent);
}
