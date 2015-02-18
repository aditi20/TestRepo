/**
 *   Grameen: Salesforce - Performance Target Manager Controller
 *   Controller for the PerformanceTargetManager page
 *
 *   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *   @author Ernesto Quesada
 */
public with sharing abstract class PerformanceTargetManagerAbstract {
    
    // Type of the manager
    public String managerType;
    
    // Get closed constant
    public String getClosed() {
        return PerformanceTargetDO.STATUS_CLOSED;
    }

    // Id of the current target
    public String currentTargetId {get; set;}

    // List of filtered performance targets to show in the manager
    public List<PerformanceTarget__c> targetList {get; set;}

    // Indicate the previous sort column
    private String previousSortField;

    // Indicate the column to sort the records (should be a field name)
    public String tableOrderColumn {
        get;
        set {
            if (
                    value == null || String.isBlank(value.trim())
                    || String.escapeSingleQuotes(value).contains('\\')
            ) {
                tableOrderColumn = 'LastModifiedDate';
            } else {
                tableOrderColumn = value.trim() ;
            }

            // Set the previous field
            previousSortField = tableOrderColumn;
        }
    }

    // Indicate the order for the rows
    private String sortOrder;

    /**
     * Class Constructor
     */
    public PerformanceTargetManagerAbstract(String managerType) {
        this.tableOrderColumn = 'LastModifiedDate desc, CreatedDate';
        this.sortOrder = 'desc';
        this.targetList = new List<PerformanceTarget__c>();
        this.managerType = managerType;
        refreshTargetList();
    }

    /**
     * Set the order and refresh the list
     */
    public void doSort() {
        this.sortOrder = (this.previousSortField == this.tableOrderColumn
                          && this.sortOrder == 'desc') ? 'asc' : 'desc';
        refreshTargetList();
    }

    /**
     * Refresh the contact group list
     */
    public void refreshTargetList() {
        try {
            this.targetList = new PerformanceTargetSelector().getAllForType(
                this.managerType,
                tableOrderColumn,
                sortOrder
            );
        } catch (Exception e) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())
            );
        }
    }

    /**
     * Close Target method
     */
    public void closeTarget() {
         PerformanceTarget__c performance = getPerformanceTarget(currentTargetId);
         PerformanceTargetDO.changeStatus(performance, PerformanceTargetDO.STATUS_CLOSED);
    }

    /**
     * Search for a Performance target by Id in the listViews
     *
     * @param   targetId    the Id of the target to look forget
     * @return              the PerformanceTarget object
     */
    private PerformanceTarget__c getPerformanceTarget(Id targetId) {
        for (PerformanceTarget__c target : targetList) {
            if (target.Id == (targetId)) {
                return target;
            }
        }
        return null;
    }
}
