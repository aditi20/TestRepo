/**
 * Helper class that carries out shared email functionality
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 *
 * @author - Owen Davies
 */
public with sharing class EmailUtils {

    // No reply email address for TaroWorks
    public static final String NO_REPLY_ADDRESS = 'no-reply@taroworks.org';

    /**
     * Create a single email that is to be sent to the current user.
     * Set to have the no-reply email address
     * Set it to be UTF-8 so it can handle non-latin characters.
     *
     * @return - The email to be sent out 
     */
    public static Messaging.SingleEmailMessage createSingleEmailForCurrentUser() {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setSaveAsActivity(false);
        mail.setReplyTo(EmailUtils.NO_REPLY_ADDRESS);
        mail.setCharset('UTF-8');
        return mail;
    }
}