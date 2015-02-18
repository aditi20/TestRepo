/**
 *Test class for SiteUrlRewritter
 */
@isTest
public with sharing class SiteUrlRewriterTest {

    public static testMethod void testMapRequestUrl() {
        SiteUrlRewriter rewriter = new SiteUrlRewriter();
        System.assertEquals(
            Page.formList.getUrl(),
            rewriter.mapRequestUrl( new PageReference('/formList')).getUrl()
        );
        System.assertEquals(
            Page.formList.getUrl(),
            rewriter.mapRequestUrl( new PageReference('/apex/formlist')).getUrl()
        );
        System.assertEquals(
            Page.Submission.getUrl(),
            rewriter.mapRequestUrl( new PageReference('/Submission')).getUrl()
        );
        System.assertEquals(
            Page.DownloadApk.getUrl(),
            rewriter.mapRequestUrl( new PageReference('/DownloadApk')).getUrl()
        );
        PageReference otherPageReference = new PageReference('/other');
        System.assertEquals(
            otherPageReference.getUrl(),
            rewriter.mapRequestUrl(otherPageReference).getUrl()
        );
    }

    public static testMethod void testGenerateUrlFor() {
        SiteUrlRewriter rewriter = new SiteUrlRewriter();
        System.assertEquals(null, rewriter.generateUrlFor(new List<PageReference>{}));
    }
}