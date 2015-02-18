/**
 *   Grameen: Salesforce - Performance Indicator Target Manager Controller
 *   Controller for the PerformanceTargetManager page
 *
 *   (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 *   @author Ernesto Quesada
 */
public with sharing class IndicatorManagerController extends PerformanceTargetManagerAbstract{
    
    /**
     * Class Constructor
     */
    public IndicatorManagerController() {
        super(PerformanceTargetDO.TYPE_INDICATOR);
    }
    
}
