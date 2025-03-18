@isTest
public class NumberToCharacterTest {
    
    /**
     * Tests the conversion of whole numbers without decimal places
     */
    @isTest
    static void testWholeNumbers() {
        // Test simple whole numbers
        System.assertEquals(' One Rupees Only', NumberToCharacter.getNumberTOWordConvertion(1));
        System.assertEquals(' Twenty Rupees Only', NumberToCharacter.getNumberTOWordConvertion(20));
        System.assertEquals(' Ninety Rupees Only', NumberToCharacter.getNumberTOWordConvertion(90));
        
        // Test teen numbers
        System.assertEquals(' Eleven Rupees Only', NumberToCharacter.getNumberTOWordConvertion(11));
        System.assertEquals(' Nineteen Rupees Only', NumberToCharacter.getNumberTOWordConvertion(19));
        
        // Test hundreds
        System.assertEquals(' One Hundred Rupees Only', NumberToCharacter.getNumberTOWordConvertion(100));
        System.assertEquals(' Five Hundred and Twenty Three Rupees Only', NumberToCharacter.getNumberTOWordConvertion(523));
        
        // Test thousands
        System.assertEquals(' One Thousand Rupees Only', NumberToCharacter.getNumberTOWordConvertion(1000));
        System.assertEquals(' Nine Thousand Nine Hundred and Ninety Nine Rupees Only', NumberToCharacter.getNumberTOWordConvertion(9999));
        
        // Test specific cases for ten-thousands
        System.assertEquals(' Ten Thousand Rupees Only', NumberToCharacter.getNumberTOWordConvertion(10000));
        System.assertEquals(' Eleven Thousand Rupees Only', NumberToCharacter.getNumberTOWordConvertion(11000));
        System.assertEquals(' Twenty Five Thousand Six Hundred and Thirty Four Rupees Only', NumberToCharacter.getNumberTOWordConvertion(25634));
        
        // Test lakhs (hundred thousands)
        System.assertEquals(' One Lakh Rupees Only', NumberToCharacter.getNumberTOWordConvertion(100000));
        System.assertEquals(' Five Lakh Forty Three Thousand Two Hundred and Twenty One Rupees Only', NumberToCharacter.getNumberTOWordConvertion(543221));
        
        // Test ten-lakhs
        System.assertEquals(' Ten Lakh Rupees Only', NumberToCharacter.getNumberTOWordConvertion(1000000));
        System.assertEquals(' Fifty Five Lakh Rupees Only', NumberToCharacter.getNumberTOWordConvertion(5500000));
        
        // Test crores (ten millions)
        System.assertEquals(' One Crore Rupees Only', NumberToCharacter.getNumberTOWordConvertion(10000000));
        System.assertEquals(' Nine Crore Ninety Nine Lakh Ninety Nine Thousand Nine Hundred and Ninety Nine Rupees Only', NumberToCharacter.getNumberTOWordConvertion(99999999));
        
        // Test ten-crores
        System.assertEquals(' Ten Crore Rupees Only', NumberToCharacter.getNumberTOWordConvertion(100000000));
        System.assertEquals(' Ninety Nine Crore Rupees Only', NumberToCharacter.getNumberTOWordConvertion(990000000));
    }
    
    
    @isTest
    static void testConvertInWordsMethod() {
        // Test direct conversion for unit place
        String[] numRev = new String[]{'1'};
        String[] actnum = new String[]{'1'};
        //System.assertEquals(' One Only', NumberToCharacter.convertInWords(numRev, actnum));
        
        // Test direct conversion for tens place
        numRev = new String[]{'2', '3'};
        actnum = new String[]{'2', '3'};
        System.assertEquals(' Thirty Two Only', NumberToCharacter.convertInWords(numRev, actnum));
        
        // Test direct conversion for hundreds place
        numRev = new String[]{'3', '2', '1'};
        actnum = new String[]{'3', '2', '1'};
        System.assertEquals(' One Hundred and Twenty Three Only', NumberToCharacter.convertInWords(numRev, actnum));
        
        // Test direct conversion for thousands place
        numRev = new String[]{'4', '3', '2', '1'};
        actnum = new String[]{'4', '3', '2', '1'};
        //System.assertEquals(' One Thousand Two Hundred and Thirty Four Only', NumberToCharacter.convertInWords(numRev, actnum));
        
        // Test direct conversion with teen numbers
        numRev = new String[]{'1', '1'};
        actnum = new String[]{'1', '1'};
        System.assertEquals(' Eleven Only', NumberToCharacter.convertInWords(numRev, actnum));
        
        // Test direct conversion with zeros
        numRev = new String[]{'0', '0', '1'};
        actnum = new String[]{'0', '0', '1'};
        System.assertEquals(' One Hundred Only', NumberToCharacter.convertInWords(numRev, actnum));
    }
}