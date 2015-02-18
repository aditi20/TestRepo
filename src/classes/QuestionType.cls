/**
 * Class to process the xform creation
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
public with sharing class QuestionType {

    /*Question values*/
    public static final Map<String, Set<String>> QuestionTypeToSchemaType = new Map<String, Set<String>> {
        QuestionDO.TYPE_TEXT_SHORT      => new Set<String> {Schema.Displaytype.TextArea.name(),
                                                           Schema.Displaytype.String.name()},

        QuestionDO.TYPE_TEXT_LONG       => new Set<String> {Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_NUMBER          => new Set<String> {Schema.Displaytype.Double.name(),
                                                           Schema.Displaytype.Currency.name(),
                                                           Schema.Displaytype.Percent.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_NUMBER_INTEGER  => new Set<String> {Schema.Displaytype.Double.name(),
                                                           Schema.Displaytype.Integer.name(),
                                                           Schema.Displaytype.Currency.name(),
                                                           Schema.Displaytype.Percent.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_NUMBER_DECIMAL  => new Set<String> {Schema.Displaytype.Double.name(),
                                                           Schema.Displaytype.Currency.name(),
                                                           Schema.Displaytype.Percent.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_DATE            => new Set<String> {Schema.Displaytype.Date.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_DATETIME        => new Set<String> {Schema.Displaytype.DateTime.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_BARCODE         => new Set<String> {Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_RADIO           => new Set<String> {Schema.Displaytype.Picklist.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_CHECKBOX        => new Set<String> {Schema.Displaytype.MultiPicklist.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_MEDIA_IMAGE     => new Set<String> {Schema.Displaytype.TextArea.name(),
                                                           Schema.Displaytype.String.name()},

        QuestionDO.TYPE_SIGNATURE       => new Set<String> {Schema.Displaytype.TextArea.name(),
                                                           Schema.Displaytype.String.name()},

        QuestionDO.TYPE_MEDIA_IMAGE     => new Set<String> {Schema.Displaytype.Url.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_SIGNATURE       => new Set<String> {Schema.Displaytype.Url.name(),
                                                           Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDO.TYPE_CASCADING_LEVEL => new Set<String> {Schema.Displaytype.String.name(),
                                                           Schema.Displaytype.TextArea.name()},

        QuestionDo.TYPE_GPS             => new Set<String> {Schema.Displaytype.Location.name()} 
    };

    public static String logics;

    public static final Set<String> NUMERIC_TYPES = new Set<String> {
        QuestionDO.TYPE_NUMBER,
        QuestionDO.TYPE_NUMBER_INTEGER,
        QuestionDO.TYPE_NUMBER_DECIMAL
    };

    public static final Set<String> SELECT_TYPES = new Set<String> {
        QuestionDO.TYPE_RADIO, QuestionDO.TYPE_CHECKBOX
    };

    /*String Xforms types*/
    public static Map<String, String> XFORMTYPE_BY_QUESTIONTYPE = new Map<String, String> {
        QuestionDO.TYPE_DATETIME        => 'dateTime',
        QuestionDO.TYPE_DATE            => 'date',
        QuestionDO.TYPE_BARCODE         => 'barcode',
        QuestionDO.TYPE_TEXT_LONG       => 'string',
        QuestionDO.TYPE_TEXT_SHORT      => 'string',
        QuestionDO.TYPE_STATIC          => 'string',
        QuestionDO.TYPE_FINAL           => 'string',
        QuestionDO.TYPE_NUMBER          => 'int',
        QuestionDO.TYPE_NUMBER_INTEGER  => 'int',
        QuestionDO.TYPE_NUMBER_DECIMAL  => 'decimal',
        QuestionDO.TYPE_RADIO           => 'select1',
        QuestionDO.TYPE_CHECKBOX        => 'select',
        QuestionDO.TYPE_MEDIA_IMAGE     => 'binary',
        QuestionDO.TYPE_SIGNATURE       => 'binary',
        QuestionDO.TYPE_CASCADING_LEVEL => 'select1',
        QuestionDo.TYPE_GPS             => 'geopoint'
    };

    //Media types for the Media Question
    public static final String MEDIATYPE_IMAGE = 'image/*';

    /**
     * Method to get the logic for the Xform generation
     *
     * @param  skipCondition a skip condition to generate the relevant
     * @param  questionPaths a map with the path for each question
     * @return               the relevant string
     */
    public static String getRelevants(SkipCondition__c skipCondition, Map<Id, String> questionPaths) {
        String relevantString = '';

        if(SELECT_TYPES.contains(skipCondition.SourceQuestion__r.Type__c.toLowerCase())) {
            String value;
            String conditionType;

            if(skipCondition.Condition__c == SkipConditionDO.CONDITION_EQUAL) {
                value = skipCondition.SkipValue__c;
                relevantString = 'selected(' + questionPaths.get(skipCondition.SourceQuestion__c) +
                                 ',' + '\'' + value + '\'' + ')';

                if(skipCondition.Negate__c) {
                    relevantString = 'not(' + relevantString + ')';
                }
            }
            else if(skipCondition.Condition__c == SkipConditionDO.CONDITION_ISANSWERED) {
                relevantString = questionPaths.get(skipCondition.SourceQuestion__c) +
                                 (skipCondition.Negate__c ? '=' : '!=') + '\'\'';
            }
        }
        else {
            String value;
            String conditionType;

            if(skipCondition.Condition__c == SkipConditionDO.CONDITION_ISANSWERED) {
                conditionType = skipCondition.Negate__c ? '=' : '!=';
                value = '\'\'';
            }
            else {
                if(skipCondition.Condition__c == SkipConditionDO.CONDITION_GREATER) {
                    conditionType = skipCondition.Negate__c ? '<=' : '>';
                }
                else if(skipCondition.Condition__c == SkipConditionDO.CONDITION_LESSER) {
                    conditionType = skipCondition.Negate__c ? '>=' : '<';
                }
                else if(skipCondition.Condition__c == SkipConditionDO.CONDITION_EQUAL) {
                    conditionType = skipCondition.Negate__c ? '!=' : '=';
                }

                value = skipCondition.SkipValue__c;

                if(!NUMERIC_TYPES.contains(skipCondition.SourceQuestion__r.Type__c.toLowerCase())) {
                    value = '\'' + value + '\'';
                }
            }

            relevantString = questionPaths.get(skipCondition.SourceQuestion__c) + conditionType + value;
        }

        return relevantString;
    }

    // used for marking all question
    public with sharing abstract class IQuestion {
        public  String name                   { get; set; }
        public  String caption                { get; set; }
        public  String hints                  { get; set; }
        public  String type                   { get; set; }
        private String questionRelevant       { get; set; }
        private String parentRelevant         { get; set; }
        public Question__c question           { get; set; }

        public IQuestion(Question__c q) {
            this.type = q.Type__c;
            this.caption = (q.Caption__c == null) ? q.Name : q.Caption__c;
            this.name = String.valueOf(q.Name);
            this.hints = (q.Hint__c == null) ? '' : q.Hint__c;

        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public abstract void getXFormsModel(dom.XmlNode xmlModel);

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public abstract void getXFormBody(dom.XmlNode xmlBody);

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public abstract void getBindings(
                Dom.XmlNode xmlBody,
                List<SkipCondition__c> skipConditions,
                List<QuestionMapping__c> questionMappings,
                Map<Id, String> questionPaths,
                Map<String, Schema.SObjectType> globalDescribe,
                String finalizeConditions);

        public String getRelevant() {
            return questionRelevant;
        }

        private String getQuestionRelevantAndSection(
            List<SkipCondition__c> skipConditions,
            Map<Id, String> questionPaths,
            Id questionId,
            String operator,
            String behavior
        ) {

            String allRelevants = getQuestionRelevant(
                skipConditions,
                questionPaths,
                questionId,
                operator,
                behavior
            );

            if(allRelevants != '' && allRelevants != null) {
                allRelevants  = (this.parentRelevant != null && this.parentRelevant != '')
                                                    ? allRelevants + ' and ' + this.parentRelevant
                                                    : allRelevants;
            }
            else {
                allRelevants = this.parentRelevant;
            }

            questionRelevant = allRelevants;
            return questionRelevant;
        }

        private String getQuestionRelevant(
                List<SkipCondition__c> skipConditions,
                Map<Id, String> questionPaths,
                Id questionId,
                String operator,
                String behavior
        ) {
            String relevant = '';
            String xFormOperator = (operator == 'Any') ? ' or ' : ' and ';

            for (SkipCondition__c sk : skipConditions) {
                if(sk.Parent__c == questionId) {
                     relevant += (relevant != '' ?  xFormOperator  : '') + getRelevants(sk, questionPaths);
                }
            }

            if (String.IsNotBlank(relevant)) {
                if(behavior == 'Hide') {
                    relevant = 'not(' + relevant + ')';
                }
                else {
                    relevant = '(' + relevant + ')';
                }
            }
            // add brackets to separate logic of other questions and 'end of survey' questions
            questionRelevant = relevant;
            return questionRelevant;
        }
    }

    public class Section extends Question {
        public Boolean showInSinglePage         { get; set; }
        public List<IQuestion> sectionQuestions { get; set; }
        public String finishConditions          { get; set; }
        public Id repeatValue                   { get; set; }
        private Map<Id, String> questionPaths   { get; set; }

        public Section(Question__c q, Map<Id, String> questionPaths) {
            super(q);
            this.ShowInSinglePage = q.SamePage__c;
            sectionQuestions = new List<IQuestion>();
            this.repeatValue = q.RepeatSourceValue__c;
            this.questionPaths = questionPaths;
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            dom.xmlNode xmlSection = xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);

            for (IQuestion q : sectionQuestions) {
                    q.getXFormsModel(xmlSection);
            }
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {
            String sectionBody = '';
            String questionBody = '';

            dom.Xmlnode xmlBodySection;

            if (type == QuestionDO.TYPE_REPEAT) {
                //The secion is generated different in case is of type repeat
                xmlBodySection = xmlBody.addChildElement('group', null, null);
                xmlBodySection.addChildElement('label', null, null).addTextNode(this.Caption);

                dom.Xmlnode xmlBodySectionRepeat =  xmlBodySection.addChildElement('repeat', null, null);
                xmlBodySectionRepeat.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));

                if (repeatValue != null) {
                    xmlBodySectionRepeat.setAttribute('jr:noAddRemove', 'true()');
                    xmlBodySectionRepeat.setAttribute('jr:count', questionPaths.get(repeatValue));
                }

                if (ShowInSinglePage) {
                    //in case we need to show in a single page, we need to add another
                    //group tag inside the repeat with the field-list attribute
                    xmlBodySectionRepeat = xmlBodySectionRepeat.addChildElement('group', null, null);
                    xmlBodySectionRepeat.setAttribute('appearance', 'field-list');
                }

                for (IQuestion q : sectionQuestions) {
                    q.getXFormBody(xmlBodySectionRepeat);
                }

            }
            else {
                xmlBodySection =  xmlBody.addChildElement('group', null, null);
                xmlBodySection.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));

                if (ShowInSinglePage) {
                    xmlBodySection.setAttribute('appearance', 'field-list');
                }
                xmlBodySection.addChildElement('label', null, null).addTextNode(this.Caption);

                for (IQuestion q : sectionQuestions) {
                    q.getXFormBody(xmlBodySection);
                }
            }
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
                 Dom.XmlNode xmlModel,
                 List<SkipCondition__c> skipConditions,
                 List<QuestionMapping__c> questionMappings,
                 Map<Id, String> questionPaths,
                 Map<String, Schema.SObjectType> globalDescribe,
                 String allFinalizationConditions
        ) {
            String relevantValue = '';

            // Initialize the relevants with all the general
            // conditions to finalize the survey
            this.relevant = this.getQuestionRelevant(
                skipConditions,
                questionPaths,
                this.Id,
                this.logicOperator,
                this.logicBehavior
            );

            if(this.type == QuestionDO.TYPE_REPEAT) {
                finishConditions = allFinalizationConditions;

                if (String.isNotBlank(finishConditions)) {
                    relevantValue = 'not(' + finishConditions + ')';
                }

                if (String.isNotBlank(relevant)) {
                    relevantValue += (relevantValue == '' ? '' : ' and ') + relevant;
                }

                this.relevant = relevantValue;
            }

            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', (path + '/' + Name).replace(' ', '_'));

            // In case it is repeat based on previous value we need to ensure we only
            // show the repeat section with numbers greater than zero
            if (repeatValue != null) {
                this.relevant = (this.relevant != '' ? this.relevant + ' and ' : '') +
                                questionPaths.get(repeatValue) + ' > 0';
            }

            if (this.relevant != null && this.relevant != '') {
                 xmlBind.setAttribute('relevant', this.relevant);
            }

            if(this.Type != QuestionDO.TYPE_REPEAT) {
                finishConditions = allFinalizationConditions;
            }

            for (IQuestion q : sectionQuestions) {
                q.parentRelevant = this.relevant;
                q.getBindings(
                    xmlModel,
                    skipConditions,
                    questionMappings,
                    questionPaths,
                    globalDescribe,
                    finishConditions
                );

                if (q.Type == QuestionDO.TYPE_FINAL) {
                    finishConditions = addFinalCondition(q.getRelevant(), finishConditions);
                }
            }
        }
    }

    public with sharing abstract class Question extends IQuestion {
        public String Path          { get; set; }
        public String Id            { get; set; }
        public Boolean Required     { get; set; }
        public String logicBehavior { get; set; }
        public String logicOperator { get; set; }
        private String typeXml      { get; set; }
        public String relevant      { get; set; }





        public Question(Question__c q) {
            super(q);
            this.Id = q.Id;
            this.logicBehavior = q.SkipLogicBehavior__c;
            this.logicOperator = q.SkipLogicOperator__c;
            this.Required = q.Required__c != null && q.Required__c;
            this.typeXml = XFORMTYPE_BY_QUESTIONTYPE.get(this.Type);
        }

        /**
         * Set a new condition to finish the survey
         *
         * @param xmlBind            the bind node of the question
         * @param finalizeConditions all the conditions that end the survey
         */
        public void setRelevantToBind(dom.XmlNode xmlBind, String finalizeConditions) {
            String relevantValue = '';
            if (String.isNotBlank(finalizeConditions)) {
                relevantValue = 'not(' + finalizeConditions + ')';
            }
            if (String.isNotBlank(relevant)) {
                relevantValue += (relevantValue == '' ? '' : ' and ') + relevant;
            }
            if (String.isNotBlank(relevantValue)) {
                xmlBind.setAttribute('relevant', relevantValue);
            }
        }
    }

    public class SimpleInput extends Question {
        public double Maximum       { get; set; }
        public double Minimum       { get; set; }

        public SimpleInput(Question__c q) {
            super(q);
            this.Maximum = q.Maximum__c;
            this.Minimum = q.Minimum__c;
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {

            dom.Xmlnode xmlIntervieweeInput = xmlBody.addChildElement('input', null, null);
            xmlIntervieweeInput.setAttribute('ref', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlIntervieweeInput.addChildElement('label', null, null).addTextNode(this.Caption);

            if (String.isNotBlank(this.Hints)) {
                xmlIntervieweeInput.addChildElement('hint', null, null).addTextNode(this.Hints);
            }
        }

        /**
         * Return the max length the QuestionMapping's field can hold.
         *
         * @param  globalDescribe  the System.getGlobalDescribe() instance.
         * @param  questionMapping the question mapping object whose field we're interested.
         * @return                 the max length the QuestionMapping's field can hold.
         */
        private Integer getFieldLength(
            Map<String, Schema.SObjectType> globalDescribe,
            QuestionMapping__c questionMapping
        ) {
            Schema.DescribeSObjectResult mappedObjectDescribe =
                    globalDescribe.get(questionMapping.SurveyMapping__r.ObjectApiName__c).getDescribe();
            Map<String, Schema.SObjectField> fieldDescribeMap = mappedObjectDescribe.fields.getMap();
            return fieldDescribeMap.get(questionMapping.FieldApiName__c).getDescribe().getLength();
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizationConditions
        ) {
            String max;
            String min;
            String constraint;

            if (this.Maximum == null) {
                max = '';
            }
            else {
                //When a zero prints as String from a double value 0.0 is the output and
                //when format is applied it's converted the output to 0
                max = (this.Maximum == 0)
                      ? this.Maximum.format()
                      : Decimal.valueOf(this.Maximum).stripTrailingZeros().toPlainString();
            }

            if (this.Minimum == null) {
                min = '';
            }
            else {
                //When a zero prints as String from a double value 0.0 is the output and
                //when format is applied it's converted the output to 0
                min = (this.Minimum == 0)
                      ? this.Minimum.format()
                      : Decimal.valueOf(this.Minimum).stripTrailingZeros().toPlainString();
            }

            Integer maxLength = -1;
            String constraintMsg;

            if (this.Type == QuestionDO.TYPE_TEXT_SHORT) {
                if (!questionMappings.isEmpty()) {
                    for (QuestionMapping__c qm : questionMappings) {
                        if (qm.Question__c == Id) {
                            Integer fieldLength = getFieldLength(globalDescribe, qm);
                            if (maxLength == -1) {
                                maxLength = fieldLength;
                            } else {
                                maxLength = math.min(maxLength, fieldLength);
                            }
                        }
                    }
                }

                if (maxLength == -1) {
                    maxLength = 50;
                }

                constraint = 'regex(.,\'^[\\w\\W]{0,' + maxLength + '}$\')';
                constraintMsg = 'Invalid response: the response exceeds ' + maxLength + ' characters.';
            }

            else if (NUMERIC_TYPES.contains(this.Type.toLowerCase())) {
                if (max != '' && min != '') {
                    constraint = '(.>=' + min + ' and .<=' + max + ')';
                    constraintMsg = 'Must be between ' + min + ' and ' + max + '.';
                }
                else if(max != '' || min != '') {
                    constraint = (max != '') ? '.<=' + max : '.>=' + min;
                    constraintMsg = 'Must not be ' + (max != '' ? 'greater' : 'lower') +
                                    ' than ' + (max != '' ? max : min) + '.';
                }
            }
            /*apply the relevant attribute for this question*/
            relevant = getQuestionRelevant(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);

            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }
            if(this.Type == QuestionDO.TYPE_STATIC) {
                xmlBind.setAttribute('readonly', 'true()');
            }
            if (constraint != '' && constraint != null) {
                xmlBind.setAttribute('jr:constraint', constraint);
                if (constraintmsg != '' && constraintmsg != null) {
                    xmlBind.setAttribute('jr:constraintMsg', constraintmsg);
                }
            }
            //set the relevants to the binding node
            this.setRelevantToBind(xmlBind, finalizationConditions);
        }
    }

    /**
     * Media Question type to use images and other media files
     */
    public virtual class MediaQuestion extends Question {

        /**
         * Constructor of the class
         *
         * @param q The base question__c for this wrapper
         */
        public MediaQuestion(Question__c q) {
            super(q);
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }


        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {

            dom.Xmlnode xmlIntervieweeInput = xmlBody.addChildElement('upload', null, null);
            xmlIntervieweeInput.setAttribute('ref', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            //for now the mediatype will allways be image
            xmlIntervieweeInput.setAttribute('mediatype', MEDIATYPE_IMAGE);

            xmlIntervieweeInput.addChildElement('label', null, null).addTextNode(this.Caption);
            if (String.isNotBlank(this.Hints)) {
                xmlIntervieweeInput.addChildElement('hint', null, null).addTextNode(this.Hints);
            }
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizationConditions
        ) {
            /*apply the relevant attribute for this question*/
            relevant = getQuestionRelevant(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);

            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }

            //set the relevants to the binding node
            this.setRelevantToBind(xmlBind, finalizationConditions);
        }
    }

    public class SignatureQuestion extends Question {
        /**
         * Constructor of the class
         *
         * @param q The base question__c for this wrapper
         */
        public SignatureQuestion(Question__c q) {
            super(q);
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }


        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {

            dom.Xmlnode xmlIntervieweeInput = xmlBody.addChildElement('upload', null, null);
            xmlIntervieweeInput.setAttribute('ref', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            //for now the mediatype will allways be image
            xmlIntervieweeInput.setAttribute('mediatype', MEDIATYPE_IMAGE);

            xmlIntervieweeInput.setAttribute('appearance', 'signature');

            xmlIntervieweeInput.addChildElement('label', null, null).addTextNode(this.Caption);
            if (String.isNotBlank(this.Hints)) {
                xmlIntervieweeInput.addChildElement('hint', null, null).addTextNode(this.Hints);
            }
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizationConditions
        ) {
            /*apply the relevant attribute for this question*/
            relevant = getQuestionRelevant(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);

            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }

            //set the relevants to the binding node
            this.setRelevantToBind(xmlBind, finalizationConditions);
        }
    }

    public class FinalizeQuestion extends Question {
        public String finishConditions             { get; set; }

        public FinalizeQuestion(Question__c q) {
            super(q);
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {
            dom.Xmlnode xmlIntervieweeInput = xmlBody.addChildElement('input', null, null);
            xmlIntervieweeInput.setAttribute('ref', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlIntervieweeInput.addChildElement('label', null, null).addTextNode(this.Caption);

            if (String.isNotBlank(this.Hints)) {
                xmlIntervieweeInput.addChildElement('hint', null, null).addTextNode(this.Hints);
            }
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizeConditions
        ) {
            /*apply the relevant attribute for this question*/
            relevant = getQuestionRelevantAndSection(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            //add the relevants of the question section to avoid ending the survey in the case that
            //the section is not shown
            finishConditions = relevant;
            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);
            xmlBind.setAttribute('readonly', 'true()');

            //add conditions to the question, these conditions will determinate if the survey ends
            this.setRelevantToBind(xmlBind, finalizeConditions);

        }
    }

    public class SelectionQuestion extends Question {
        private List<Option__c> qOptions = new List<Option__c>();

        public SelectionQuestion(Question__c question) {
            super(question);
            this.qOptions = question.Options__r;
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }
        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizeConditions
        ) {
            dom.XmlNode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);
            this.relevant = getQuestionRelevant(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }

            this.setRelevantToBind(xmlBind, finalizeConditions);
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {
            //Get all the options for the Radio Question
            if (!(path == '' || path == null)) {
                path = path + '/';
            }

            dom.xmlNode xmlSelect = xmlBody.addChildElement(typeXml, null, null);
            xmlSelect.setAttribute('ref', path + this.Name);
            xmlSelect.addChildElement('label', null, null).addTextNode(this.Caption);

            if (String.isNotBlank(this.Hints)) {
                xmlSelect.addChildElement('hint', null, null).addTextNode(this.Hints);
            }

            for (Option__c opt : qOptions) {
                dom.xmlNode xmlItem = xmlSelect.addChildElement('item', null, null);
                xmlItem.addChildElement('label', null, null).addTextNode(opt.Caption__c);
                xmlItem.addChildElement('value', null, null).addTextNode(opt.Id);
            }
        }
    }

    public class CascadingSelectQuestion extends Question {
        List<CascadingLevel__c> levels;
        Map<Id, CascadingSelectValue__c> valuesByParentId;
        List<CascadingChildQuestion> levelQuestions;

        public CascadingSelectQuestion(
            Question__c question,
            List<CascadingLevel__c> levels,
            Map<Id, CascadingSelectValue__c> valuesMap
        ) {
            super(question);
            this.levels = levels;
            this.valuesByParentId = valuesMap;
            Integer levelCounter = 1;
            this.levelQuestions = new List<CascadingChildQuestion>();
            for(Question__c childQuestion : question.Questions__r) {
                levelQuestions.add(new CascadingChildQuestion(childQuestion, question.Name, levelCounter));
                levelCounter++;
            }
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            // Add the node corresponding to the current question
            Dom.XmlNode cascadingNode = xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);

            // Add the static question for the first screen
            cascadingNode.addChildElement(this.Name.replace(' ', '_') + '_static', null, null);

            // Find the root of the model
            Dom.XmlNode xmlModelRoot = xmlModel.getParent();
            while(xmlModelRoot.getName() != null && xmlModelRoot.getName() != 'model') {
                xmlModelRoot = xmlModelRoot.getParent();
            }

            // Generate the data for the levels and add it to the model
            generateCascadingData(xmlModelRoot);

            // Add the level questions
            for(IQuestion child : levelQuestions) {
                child.getXFormsModel(cascadingNode);
            }
        }

        /**
         * Generate the instance data and add it to the model
         *
         * @param xmlModelRoot the model root of the xform
         */
        private void generateCascadingData(Dom.XmlNode xmlModelRoot) {
            // Add an instance node for the data of the current cascading select question
            Dom.XmlNode instanceNode = xmlModelRoot.addChildElement('instance', null, null);
            instanceNode.setAttribute('id', this.Name + '_choices');

            // Add the list node for the first level
            Dom.XmlNode levelListNode = instanceNode.addChildElement(
                'level1_list',
                null,
                null
            );

            // Generate the data for the values of the values of the first level
            for(CascadingSelectValue__c value : this.levels[0].Cascading_Select_Values__r) {
                generateLevelData(
                    levelListNode,
                    this.levels,
                    1,
                    this.valuesByParentId.get(value.Id),
                    this.valuesByParentId
                );
            }
        }

        /**
         * Generate the data for the levels recursively
         *
         * @param parentNode       the parent xml node
         * @param levelsList       all the levels of the cascading select
         * @param index            the index of the current level
         * @param currentValue     the selected value for the current level
         * @param valuesByParentId a map with the values for each parent value
         */
        private void generateLevelData(
            Dom.XmlNode parentNode,
            List<CascadingLevel__c> levelsList,
            Integer index,
            CascadingSelectValue__c currentValue,
            Map<Id, CascadingSelectValue__c> valuesByParentId
        ) {
            // Add a node for the current level
            Dom.XmlNode levelNode = parentNode.addChildElement(
                'level' + index,
                null,
                null
            );
            // Add the current level value
            levelNode.addChildElement('value', null, null).addTextNode(
                valuesByParentId.get(currentValue.Id).Value__c
            );

            // Check if it is not the last level
            if(!valuesByParentId.get(currentValue.Id).Cascading_Select_Values__r.isEmpty()) {
                // Add the list node for the next level
                Dom.XmlNode levelListNode =  levelNode.addChildElement( 'level' + (index + 1) +  '_list', null, null);
                // Generate the data for all the child values of the current one
                for(CascadingSelectValue__c value : valuesByParentId.get(currentValue.Id).Cascading_Select_Values__r) {
                    generateLevelData(levelListNode, levelsList, index + 1, value, valuesByParentId);
                }
            }
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
                Dom.XmlNode xmlModel,
                List<SkipCondition__c> skipConditions,
                List<QuestionMapping__c> questionMappings,
                Map<Id, String> questionPaths,
                Map<String, Schema.SObjectType> globalDescribe,
                String finalizeConditions
        ) {
            // Initialize the relevants with all the general
            // conditions to finalize the survey
            this.relevant = this.getQuestionRelevant(
                skipConditions,
                questionPaths,
                this.Id,
                this.logicOperator,
                this.logicBehavior
            );

            // Add the bind node and set the nodeset attribute
            dom.Xmlnode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', (path + '/' + this.Name).replace(' ', '_'));

            // Add the bind node of the static question for the first screen
            dom.Xmlnode staticBind = xmlModel.addChildElement('bind', null, null);
            staticBind.setAttribute(
                'nodeset',
                (this.path + '/' + this.Name + '/' + this.Name + '_static').replace(' ', '_')
            );
            staticBind.setAttribute('readonly', 'true()');

            // Generate the bindings of the childs
            for (CascadingChildQuestion child : levelQuestions) {
                child.path = this.path + '/' + this.Name;
                child.parentRelevant = this.relevant;
                child.getBindings(
                    xmlModel,
                    skipConditions,
                    questionMappings,
                    questionPaths,
                    globalDescribe,
                    finalizeConditions
                );
            }

            // Set the required attribute
            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }

            // Set the relevant
            this.setRelevantToBind(xmlBind, finalizeConditions);
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {
            // Add the group node for the cascading
            dom.Xmlnode xmlBodyCascading = xmlBody.addChildElement('group', null, null);
            // Set the nodeset attribute
            xmlBodyCascading.setAttribute('nodeset', path.replace(' ', '_') + '/' + Name.replace(' ', '_'));
            // Add the label node
            xmlBodyCascading.addChildElement('label', null, null).addTextNode(this.Caption);

            // Add the body of the static question for the first screen
            dom.Xmlnode staticInput = xmlBodyCascading.addChildElement('input', null, null);
            staticInput.setAttribute(
                'ref',
                (this.path + '/' + this.Name + '/' + this.Name + '_static').replace(' ', '_')
            );
            staticInput.addChildElement('label', null, null).addTextNode(this.Caption);

            if (String.isNotBlank(this.Hints)) {
                staticInput.addChildElement('hint', null, null).addTextNode(this.Hints);
            }

            // Get the data path for the levels
            String dataPath = 'instance(\'' + this.Name + '_choices\')/';

            // Add the xform body for each level
            for (CascadingChildQuestion levelQuestion : levelQuestions) {
                // Add the current level data path part
                dataPath = dataPath + levelQuestion.levelName + '_list/' + levelQuestion.levelName;
                levelQuestion.dataPath = dataPath;
                // Generate the body for the current level
                levelQuestion.getXFormBody(xmlBodyCascading);
                // Complete the data path for the next level
                dataPath = dataPath + '[value=' + levelQuestion.path + levelQuestion.Name + ']/';
            }
        }
    }

    public class CascadingChildQuestion extends Question {
        public String dataPath {get; set;}
        public String levelName {get; set;}

        public CascadingChildQuestion(Question__c question, String parent, Integer levelNumber) {
            super(question);
            this.levelName = 'level' + levelNumber;
        }

        /**
         * Get the xform model of the question
         *
         * @param xmlModel The model node of the xform
         */
        public override void getXFormsModel(dom.XmlNode xmlModel) {
            xmlModel.addChildElement(this.Name.replace(' ', '_'), null, null);
        }

        /**
         * Get the xform binding of the question
         *
         * @param xmlModel               the model node of the xform
         * @param skipConditions         the list of the conditions of this question
         * @param questionMappings       the list of the mappings of this question
         * @param questionPaths          a Map containing the QuestionId with their xform path
         * @param globalDescribe         the describes of the mapped objects
         * @param finalizationConditions the finalize conditions
         */
        public override void getBindings(
            Dom.XmlNode xmlModel,
            List<SkipCondition__c> skipConditions,
            List<QuestionMapping__c> questionMappings,
            Map<Id, String> questionPaths,
            Map<String, Schema.SObjectType> globalDescribe,
            String finalizeConditions
        ) {
            Dom.XmlNode xmlBind = xmlModel.addChildElement('bind', null, null);
            xmlBind.setAttribute('nodeset', path.replace(' ', '_') + '/' + this.Name.replace(' ', '_'));
            xmlBind.setAttribute('type', this.typeXml);
            this.relevant = getQuestionRelevant(skipConditions, questionPaths, Id, logicOperator, logicBehavior);

            if (this.Required) {
                xmlBind.setAttribute('required', 'true()');
            }

            this.setRelevantToBind(xmlBind, finalizeConditions);
        }

        /**
         * Get the xform body of the question
         *
         * @param xmlBody The body node of the xform
         */
        public override void getXFormBody(dom.XmlNode xmlBody) {
            if (String.isNotBlank(path)) {
                path = path + '/';
            }

            dom.xmlNode xmlLevel = xmlBody.addChildElement(this.typeXml, null, null);
            xmlLevel.setAttribute('ref', path + this.Name);
            xmlLevel.addChildElement('label', null, null).addTextNode(this.Caption);

            if (String.isNotBlank(this.Hints)) {
                xmlLevel.addChildElement('hint', null, null).addTextNode(this.Hints);
            }

            Dom.XmlNode xmlItem = xmlLevel.addChildElement('itemset', null, null);
            xmlItem.setAttribute('nodeset', this.dataPath);

            Dom.XmlNode labelNode = xmlItem.addChildElement('label', null, null);
            labelNode.setAttribute('ref', 'value');
            Dom.XmlNode valueNode = xmlItem.addChildElement('value', null, null);
            valueNode.setAttribute('ref', 'value');
        }
    }

    /**
     * Set a new condition to finish the survey
     *
     * @param condition The new condition to set as a final condition
     * @param finishConditions All the conditions that end the survey
     * @return The String of all the conditions
     */
    private static String addFinalCondition(String condition, String finishConditions) {
        condition = (condition == null || condition == '') ? 'true()' : condition;

        if (String.isBlank(finishConditions) || finishConditions == null) {
            finishConditions = '(' + condition + ')';
        }
        else {
            finishConditions += ' or ' + '(' + condition + ')';
        }

        return finishConditions;
    }

}
