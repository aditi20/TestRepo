/**
 *   Grameen: Salesforce - Performance Target Manager Controller
 *   Controller for the PerformanceTargetManager page
 *
 *   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *   @author Ernesto Quesada
 */
public with sharing class PerformanceTargetManagerController extends PerformanceTargetManagerAbstract {
    
    /**
     * Class Constructor
     */
    public PerformanceTargetManagerController() {
        super(PerformanceTargetDO.TYPE_JOB_TARGET);
    }
    
}
