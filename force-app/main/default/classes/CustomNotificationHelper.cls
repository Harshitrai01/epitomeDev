/**
* @File Name : CustomNotificationHelper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : January 30, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 30, 2025 |   | Initial Version
**/

public class CustomNotificationHelper {
	@AuraEnabled
	public static void LightningStudio(){
		System.debug('Lightning Studio');
	}
}