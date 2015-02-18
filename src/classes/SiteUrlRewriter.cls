/**
 * Rewriter for URLs coming in to the TaroWorks site. This has been pretty much deprecated
 * as we are using rest resources now. This is just kept for backwards compatibility and
 * will be completely deprecated when the authentication move is made
 *
 * (c) Copyright 2013 Grameen Foundation USA. All rights reserved
 */
global class SiteUrlRewriter implements Site.UrlRewriter {

    global PageReference mapRequestUrl(PageReference friendlyUrl){
        String url = friendlyUrl.getUrl();
        if (url.startsWith('/apex/')){
            url = url.substring(5);
        }

        if (url.toLowerCase().startsWith('/formlist')) {
            return Page.formList;
        } else if (url.toLowerCase().startsWith('/submission')) {
            return Page.Submission;
        } else if(url.toLowerCase().startsWith('/downloadapk')){
            return Page.DownloadApk;
        }else{
            return friendlyUrl;
        }
    }
    global PageReference[] generateUrlFor(PageReference[] yourSalesforceUrls){
        return null;
    }
}