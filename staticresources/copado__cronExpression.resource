var cronExpression = cronExpression || {};
cronExpression.hourly = cronExpression.hourly || {};
cronExpression.daily = cronExpression.daily || {};
cronExpression.weekly = cronExpression.weekly || {};

cronExpression.selectedTab = 'hourly';

cronExpression.hourly.EVERY_X_HOURS = 0;
cronExpression.hourly.START_HOUR = 0;
cronExpression.hourly.START_MINUTE = 0;
cronExpression.hourly.RADIOGROUP = '';

cronExpression.daily.EVERY_X_DAYS = 0;
cronExpression.daily.START_HOUR = 0;
cronExpression.daily.START_MINUTE = 0;
cronExpression.daily.RADIOGROUP = '';


cronExpression.weekly.START_HOUR = 0;
cronExpression.weekly.START_MINUTE = 0;

cronExpression.result = '';

cronExpression.weekly.concatDaysOfWeek = function(){
	var chkArray = [];
	
	$copado(".js-chk:checked").each(function() {
		chkArray.push($copado(this).val());
	});
	var selected = chkArray.join(',');
	return selected;
};
cronExpression.getValues = function(){
	cronExpression.hourly.EVERY_X_HOURS = document.getElementById('hourlyEvery').value;
	cronExpression.hourly.START_HOUR = document.getElementById('hourlyHourPart').value;
	cronExpression.hourly.START_MINUTE = document.getElementById('hourlyMinPart').value;

	cronExpression.daily.EVERY_X_DAYS = document.getElementById('dailyEvery').value;
	cronExpression.daily.START_HOUR = document.getElementById('dailyHourPart').value;
	cronExpression.daily.START_MINUTE = document.getElementById('dailyMinPart').value;

	cronExpression.weekly.START_HOUR = document.getElementById('weeklyHourPart').value;
	cronExpression.weekly.START_MINUTE = document.getElementById('weeklyMinPart').value;
}
cronExpression.calculate = function(){
	cronExpression.getValues();
	cronExpression.result = '';
	if(cronExpression.selectedTab=='hourly'){
		if(cronExpression.hourly.RADIOGROUP=='every'){
			cronExpression.result = '0 0 0/'+cronExpression.hourly.EVERY_X_HOURS+' 1/1 * ? *';
		}
		else if(cronExpression.hourly.RADIOGROUP=='starts'){
			cronExpression.result = '0 '+cronExpression.hourly.START_MINUTE+' '+cronExpression.hourly.START_HOUR+' 1/1 * ? *';
		}
	}
	if(cronExpression.selectedTab=='daily'){
		if(cronExpression.daily.RADIOGROUP=='every'){
			cronExpression.result = '0 '+cronExpression.daily.START_MINUTE+' '+cronExpression.daily.START_HOUR+' 1/'+cronExpression.daily.EVERY_X_DAYS+' * ? *';
		}
		else if(cronExpression.daily.RADIOGROUP=='weekdays'){
			cronExpression.result = '0 '+cronExpression.daily.START_MINUTE+' '+cronExpression.daily.START_HOUR+' ? * MON-FRI *';
		}
	}
	if(cronExpression.selectedTab=='weekly'){
		var daysOfWeek = cronExpression.weekly.concatDaysOfWeek();
		cronExpression.result = '0 '+cronExpression.weekly.START_MINUTE+' '+cronExpression.weekly.START_HOUR+' ? * '+daysOfWeek+' *';
	}
	$copado('input[id$="if_cronExpression"]').val(cronExpression.result);
	return cronExpression.result;
};
cronExpression.showCronExpression = function(){
	$copado('input[id$="if_cronExpression"]').show();
};
cronExpression.hideCronExpression = function(){
	$copado('input[id$="if_cronExpression"]').hide();
};
