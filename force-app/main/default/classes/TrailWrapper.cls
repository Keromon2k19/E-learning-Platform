public with sharing class TrailWrapper {
  private final String SUCCESS_UNIT = 'Success';
  private final String COMPLETED_MODULE = 'Completed';

  private Id userId;
  private Id trailId;
  private List<User_Module__c> userModulesWithUserUnits;
  private Set<Id> moduleIds = new Set<Id>();

  // CHECK Módulos con Unidades relacionadas
  private List<Module__c> modules = new List<Module__c>();
  // CHECK Ids de módulos relacionados al Trail actual en los que el Alumno ya aprobó
  private Set<Id> passedModuleIds = new Set<Id>();
  // CHECK Ids de Unidades relacionadas a módulos del Trail actual que el Alumno ya aprobó
  private Set<Id> passedUnitIds = new Set<Id>();
  // CHECK Registro de Trail solicitado
  public Trail__c trail;
  // CHECK Porcentaje de progreso del Alumno en el Trail
  public Integer progressTrail;

  public TrailWrapper(Id trailId, Id userId) {
    this.userId = userId;
    this.trailId = trailId;
    initializeProperties(trailId);
  }

  private void initializeProperties(Id trailId) {
    this.queryTrail();
    this.setModuleIds();

    this.queryModules();

    this.queryPassedModulesAndUnits();
    this.setPassedModulesAndUnits();

    this.setProgress();
  }

  private void setProgress() {
    Decimal totalModules = moduleIds.size();
    Decimal passedModules = passedModuleIds.size();
    this.progressTrail = ((passedModules / totalModules) * 100).intValue();
  }

  private void queryPassedModulesAndUnits() {
    this.userModulesWithUserUnits = [
      SELECT
        Id,
        Module__c,
        Status__c,
        (SELECT Unit__c FROM User_Units__r WHERE Status__c = :SUCCESS_UNIT)
      FROM User_Module__c
      WHERE User__c = :this.userId AND Module__c IN :moduleIds
    ];
  }

  private void queryModules() {
    this.modules = [
      SELECT
        Id,
        Name,
        Description__c,
        Role__c,
        Skills__c,
        Total_Points__c,
        Unit_Count__c,
        (SELECT Id, Name, Points__c, Duration__c FROM Units__r)
      FROM Module__c
      WHERE Id IN :this.moduleIds
    ];
  }

  private void queryTrail() {
    this.trail = [
      SELECT
        Name,
        Description__c,
        Total_Points__c,
        Duration__c,
        (
          SELECT Module__c
          FROM Trail_Modules__r
        )
      FROM Trail__c
      WHERE Id = :trailId
    ];
  }

  private void setPassedModulesAndUnits() {
    for (User_Module__c userModule : this.userModulesWithUserUnits) {
      if (userModule.Status__c == COMPLETED_MODULE) {
        this.passedModuleIds.add(userModule.Module__c);
      }
      for (User_Unit__c userUnit : userModule.User_Units__r) {
        this.passedUnitIds.add(userUnit.Unit__c);
      }
    }
  }

  private void setModuleIds() {
    for (Trail_Module__c trailModule : this.trail.Trail_Modules__r) {
      this.moduleIds.add(trailModule.Module__c);
    }
  }

  public List<Module__c> getModules() {
    return this.modules;
  }
  public Set<Id> getPassedModuleIds() {
    return this.passedModuleIds;
  }
  public Set<Id> getPassedUnitIds() {
    return this.passedUnitIds;
  }
}
