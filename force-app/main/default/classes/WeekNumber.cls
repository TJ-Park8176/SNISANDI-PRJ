/**
 * Created by MZC01-DGCHOI on 2023-02-17.
 */

public with sharing class WeekNumber {

    public Boolean isThisMonth; //이번달인지
    public Integer batchWeekOfYear; //연간 주차
    public Integer batchWeekOfMonth; //월간 주차
    public Integer batchMonth; //가져와야하는 월

    public WeekNumber(Date stdDate) {
        setBatchWeekOfYear(stdDate);
        setBatchWeekOfMonth(stdDate);
    }

    //N(0~53)주차 GET
    public void setBatchWeekOfYear(Date stdDate) {
        //기준: 월  ~ 일
        DateTime batchDateTime = DateTime.newInstance(stdDate, Time.newInstance(11,59,59,0)); //DateTime.now()로 바꿔야함

        System.debug('batchDateTime ::::: ' + batchDateTime);

        Integer dayOfWeek = Integer.valueOf(batchDateTime.format('u')) - 1; //0:월요일 - 6:일요일
        Integer dayOfYear = stdDate.dayOfYear(); //365일 중 몇일?

        DateTime initDate      = DateTime.newInstance(stdDate.year(), 1,1);
        Integer  initDayOfWeek = Integer.valueOf(initDate.format('u')) - 1; //1.1일이 무슨요일인지

        Integer returnValue = 0;
        if(initDayOfWeek != 6) { //1.1이 월~토요일인 경우
            this.batchWeekOfYear = (dayOfYear<=7-initDayOfWeek) ? 1 : (dayOfYear + (initDayOfWeek-1) -dayOfWeek)/7 + 1;
        } else { //1.1이 일요일인 경우
            this.batchWeekOfYear = (dayOfYear<=8)? 1 : (dayOfYear-dayOfWeek-1)/7 + 1;
        }
    }

    //해당 월에 몇번째 주차인지....(월요일 시작 기준)
    public void setBatchWeekOfMonth(Date stdDate) {
        if(stdDate.month() == 1) { //1월일 경우
            this.batchWeekOfMonth = this.batchWeekOfYear;
            this.isThisMonth = true;
            this.batchMonth = 1;
            return;
        }

        Datetime firstDate = Datetime.newInstance(stdDate.year(), stdDate.month(), 1, 11, 59, 59); //해당 월 1일
        Integer firstDayOfWeek = Integer.valueOf(firstDate.format('u')) - 1; //해당 월 1일이 무슨 요일인지

        Integer batchDayOfMonth = stdDate.day(); //오늘이 해당 월 몇일인지

        Integer calcNum = 0;
        if(firstDayOfWeek == 0) { //1일이 월요일일 때
            calcNum = batchDayOfMonth-1;
        } else {
            calcNum = firstDayOfWeek + batchDayOfMonth - 8; //첫 월요일이 0, 전 월의 주차로 해야할 경우에는 음수(-)
        }

        if(calcNum < 0) {
            Datetime tmpDate = Datetime.newInstance(stdDate.year(), stdDate.month()-1, 1);
            this.isThisMonth = false;
            this.batchMonth = tmpDate.month();
            Datetime prevFirstDate = Datetime.newInstance(stdDate.year(), stdDate.month()-1, 1); //전 월 1일
            Integer prevfirstDayOfWeek = Integer.valueOf(prevFirstDate.format('u')) - 1; //전 월 1일이 무슨 요일인지

            Integer prevNumberOfDays = Date.daysInMonth(stdDate.year(), stdDate.month()-1); // 전 월 마지막 일
            calcNum = prevfirstDayOfWeek + prevNumberOfDays - 8;
        } else { //당월
            this.isThisMonth = true;
            this.batchMonth = stdDate.month();
        }

        this.batchWeekOfMonth = Integer.valueOf(Math.floor(calcNum / 7)) + 1;
    }


}