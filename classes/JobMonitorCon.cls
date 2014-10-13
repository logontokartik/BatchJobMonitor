public with sharing class JobMonitorCon {
	public JobMonitorCon() {
		
	}

	@RemoteAction
	public static List<ApexClass> getApexClasses(){

		List<ApexClass> classes = new List<ApexClass>();

		for(ApexClass ac : [Select Id, Name, Status, Body from ApexClass where Status = 'Active']){
			// Only chose the ones that are schedulable and have empty constructor defined
			if(ac.Body.contains('Schedulable') && ac.Body.contains('implements') && ac.Name != 'JobMonitorCon'){
				classes.add(ac);
			}
		}

		return classes;

	}

	@RemoteAction
	public static void scheduleApexJob(String apexClass,String dtString, String tmString,String selOptions, String selDays){
		
		/*Type schType = Type.forName(apexClass);
		BatchCaseUpdates bJob = new BatchCaseUpdates();
		String cron = 	'0 0 15 * * ?';	
		System.schedule('Sample Scheduled Job', cron, bJob);*/


	}

	@RemoteAction 
	public static List<WrapAsyncJob> getJobDetails(String jStatus){

		if(jStatus == null || jStatus == '')
			jStatus = 'Completed';

		List<AsyncApexJob> aJobs = new List<AsyncApexJob>();
		List<WrapAsyncJob> wJobs = new List<WrapAsyncJob>();

		aJobs = [SELECT ApexClassId,CompletedDate,CreatedById,CreatedDate,ExtendedStatus,Id,JobItemsProcessed,JobType,LastProcessed,LastProcessedOffset,MethodName,NumberOfErrors,ParentJobId,TotalJobItems,Status FROM AsyncApexJob where Status = :jStatus order by CreatedDate desc];

		Set<Id> apexClasses = new Set<Id>();
		Set<Id> userIds     = new Set<Id>();
		Map<Id,ApexClass> apexClassMap;
		Map<Id,User> userMap;

		for(AsyncApexJob a : aJobs){
			if(a.ApexClassId != null)
				apexClasses.add(a.ApexClassId);
			userIds.add(a.CreatedById);
		}

		apexClassMap = new Map<Id,ApexClass>([Select Id,Name from ApexClass where Id in :apexClasses]);
		userMap      = new Map<Id,User>([Select Id, Name, Username from User where Id in :userIds]);

		for(AsyncApexJob a : aJobs){
			wJobs.add(new WrapAsyncJob(a,apexClassMap.get(a.ApexClassId).Name,userMap.get(a.CreatedById).Name));
		}

		return wJobs;
	}


	@RemoteAction
	public static List<WrapJob> getAllJobs(){

		List<WrapJob> jobs = new List<WrapJob>();

		Map<String,WrapJob> jobMap = new Map<String,WrapJob>();

		jobMap.put('Completed',new WrapJob('Completed',0));
		jobMap.put('Processing',new WrapJob('Processing',0));
		jobMap.put('Aborted',new WrapJob('Aborted',0));
		jobMap.put('Failed',new WrapJob('Failed',0));
		jobMap.put('Queued',new WrapJob('Queued',0));
		
		List<AggregateResult> results = new List<AggregateResult>();
		results = [Select Count(Id) reccount, Status from AsyncApexJob group by Status];
		for(AggregateResult ar : results){
			jobMap.put(String.valueOf(ar.get('Status')),new WrapJob(String.valueOf(ar.get('Status')),Integer.valueOf(ar.get('reccount'))));
		}

		return jobMap.values();

	}

	public class WrapJob {
		public String type   {get;set;}
		public Integer count {get;set;}

		public WrapJob(String t, Integer c){
			this.type  = t;
			this.count = c;
		}
	}

	public class WrapAsyncJob {
		public AsyncApexJob asyncJob    {get;set;}
		public String className     	{get;set;}
		public String createdByName 	{get;set;}
		
		public WrapAsyncJob(AsyncApexJob aj, String cl, String cr){
			this.asyncJob = aj;
			this.className = cl;
			this.createdByName = cr;
		}

	}

}