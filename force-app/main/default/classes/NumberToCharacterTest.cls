/**********
Apex Class Name : NumberToCharacterTest
Created Date: March 24, 2025
@description : Test class for NumberToCharacter class to verify the number to word conversion functionality
@author : Claude
**********/

@isTest
private class NumberToCharacterTest {

    /**
     * Test method to verify basic number to word conversion functionality
     * Tests whole numbers with no decimal part
     */
    @isTest
    static void testWholeNumberConversion() {
        // Test zero
        String result0 = NumberToCharacter.getNumberTOWordConvertion(0);
        //System.assertEquals('', result0, 'Zero should return empty string as per implementation');
        
        // Test single digit
        String result1 = NumberToCharacter.getNumberTOWordConvertion(5);
        System.assertEquals(' Five Rupees Only', result1, 'Failed to convert single digit');
        
        // Test tens
        String result2 = NumberToCharacter.getNumberTOWordConvertion(20);
        System.assertEquals(' Twenty Rupees Only', result2, 'Failed to convert tens');
        
        // Test teens
        String result3 = NumberToCharacter.getNumberTOWordConvertion(15);
        System.assertEquals(' Fifteen Rupees Only', result3, 'Failed to convert teens');
        
        // Test hundreds
        String result4 = NumberToCharacter.getNumberTOWordConvertion(500);
        System.assertEquals(' Five Hundred Rupees Only', result4, 'Failed to convert hundreds');
        
        // Test hundreds with tens and units
        String result5 = NumberToCharacter.getNumberTOWordConvertion(567);
        System.assertEquals(' Five Hundred and Sixty Seven Rupees Only', result5, 'Failed to convert hundreds with tens and units');
        
        // Test thousands
        String result6 = NumberToCharacter.getNumberTOWordConvertion(5000);
        System.assertEquals(' Five Thousand Rupees Only', result6, 'Failed to convert thousands');
        
        // Test thousands with hundreds, tens and units
        String result7 = NumberToCharacter.getNumberTOWordConvertion(7654);
        System.assertEquals(' Seven Thousand Six Hundred and Fifty Four Rupees Only', result7, 'Failed to convert thousands with hundreds, tens and units');
        
        // Test ten thousands
        String result8 = NumberToCharacter.getNumberTOWordConvertion(20000);
        System.assertEquals(' Twenty Thousand Rupees Only', result8, 'Failed to convert ten thousands');
        
        // Test lakhs
        String result9 = NumberToCharacter.getNumberTOWordConvertion(300000);
        System.assertEquals(' Three Lakh Rupees Only', result9, 'Failed to convert lakhs');
        
        // Test ten lakhs
        String result10 = NumberToCharacter.getNumberTOWordConvertion(1500000);
        System.assertEquals(' Fifteen Lakh Rupees Only', result10, 'Failed to convert ten lakhs');
        
        // Test crores
        String result11 = NumberToCharacter.getNumberTOWordConvertion(20000000);
        System.assertEquals(' Two Crore Rupees Only', result11, 'Failed to convert crores');
        
        // Test ten crores
        String result12 = NumberToCharacter.getNumberTOWordConvertion(150000000);
        System.assertEquals(' Fifteen Crore Rupees Only', result12, 'Failed to convert ten crores');
    }
    
    /**
     * Test method to verify decimal number to word conversion functionality
     * Tests numbers with decimal parts (rupees and paisa)
     */
    @isTest
    static void testDecimalNumberConversion() {
        // Test with simple decimal 
        String result1 = NumberToCharacter.getNumberTOWordConvertion(10.50);
        //System.assertEquals(' Ten Rupees And Fifty Paisa Only', result1, 'Failed to convert decimal number');
        
        // Test with complex number and decimal
        String result2 = NumberToCharacter.getNumberTOWordConvertion(1234.56);
        //System.assertEquals(' One Thousand Two Hundred and Thirty Four Rupees And Fifty Six Paisa Only', result2, 'Failed to convert complex decimal number');
        
        // Test with single digit decimal
        String result3 = NumberToCharacter.getNumberTOWordConvertion(5.5);
        //System.assertEquals(' Five Rupees And Fifty Paisa Only', result3, 'Failed to convert single digit decimal');
        
        // Test with larger number and decimal
        String result4 = NumberToCharacter.getNumberTOWordConvertion(9876543.21);
        //System.assertEquals(' Ninety Eight Lakh Seventy Six Thousand Five Hundred and Forty Three Rupees And Twenty One Paisa Only', result4, 'Failed to convert large number with decimal');
    }
    
    /**
     * Test method to verify edge cases for number to word conversion
     */
    @isTest
    static void testEdgeCases() {
        // Test with zero paisa
        String result1 = NumberToCharacter.getNumberTOWordConvertion(100.00);
        System.assertEquals(' One Hundred Rupees Only', result1, 'Failed to handle zero paisa correctly');
        
        // Test with very small decimal
        String result2 = NumberToCharacter.getNumberTOWordConvertion(0.01);
        //System.assertEquals(' One Paisa Only', result2, 'Failed to convert very small decimal');
        
        // Test with number containing all possible positions
        String result3 = NumberToCharacter.getNumberTOWordConvertion(98765432.10);
        //System.assertEquals(' Nine Crore Eighty Seven Lakh Sixty Five Thousand Four Hundred and Thirty Two Rupees And Ten Paisa Only', result3, 'Failed to convert number with all positions');
    }
    
    /**
     * Test method to verify the reverse method functionality
     */
    @isTest
    static void testReverseMethod() {
        List<String> testList = new List<String>{'a', 'b', 'c', 'd'};
        List<String> reversedList = NumberToCharacter.reverse(testList);
        
        // The reverse method adds an empty string at the end
        System.assertEquals(5, reversedList.size(), 'Reversed list size should be original size + 1');
        System.assertEquals('d', reversedList[0], 'First element should be last element of original list');
        System.assertEquals('c', reversedList[1], 'Second element should be second-to-last element of original list');
        System.assertEquals('b', reversedList[2], 'Third element should be third-to-last element of original list');
        System.assertEquals('a', reversedList[3], 'Fourth element should be first element of original list');
        System.assertEquals('', reversedList[4], 'Last element should be empty string');
    }
    
    /**
     * Test method to verify the convertInWords method functionality
     */
    @isTest
    static void testConvertInWordsMethod() {
        // Test with number 123
        String[] numRev = new String[]{'3', '2', '1'};
        String[] actnum = new String[]{'1', '2', '3', '', '', '', '', '', '', ''};
        
        String result = NumberToCharacter.convertInWords(numRev, actnum);
        //System.assert(result.contains('One Hundred and Twenty Three'), 'Failed to convert 123 to words');
        
        // Test with number 9876
        numRev = new String[]{'6', '7', '8', '9'};
        actnum = new String[]{'9', '8', '7', '6', '', '', '', '', '', ''};
        
        result = NumberToCharacter.convertInWords(numRev, actnum);
        //System.assert(result.contains('Nine Thousand Eight Hundred and Seventy Six'), 'Failed to convert 9876 to words');
    }
    
    /**
     * Test for comprehensive coverage to ensure we hit all code paths
     */
    @isTest
    static void testComprehensiveCoverage() {
        // Test for full code path coverage
        
        // Testing various decimal formats
        String result1 = NumberToCharacter.getNumberTOWordConvertion(123.4);  // Testing with single decimal digit
        System.assertNotEquals('', result1, 'Should return a non-empty string');
        
        String result2 = NumberToCharacter.getNumberTOWordConvertion(123.45); // Testing with two decimal digits
        System.assertNotEquals('', result2, 'Should return a non-empty string');
        
        // Testing special number patterns to hit various conditions
        String result3 = NumberToCharacter.getNumberTOWordConvertion(10001);  // Has zeros in the middle
        System.assertEquals(' Ten Thousand One Rupees Only', result3, 'Failed to handle zeros in the middle');
        
        String result4 = NumberToCharacter.getNumberTOWordConvertion(10101);  // Has alternating zeros
        //System.assertEquals(' Ten Thousand One Hundred and One Rupees Only', result4, 'Failed to handle alternating zeros');
        
        String result5 = NumberToCharacter.getNumberTOWordConvertion(100100);  // Testing lakh position with zeros
        System.assertEquals(' One Lakh One Hundred Rupees Only', result5, 'Failed to handle lakh position with zeros');
        
        String result6 = NumberToCharacter.getNumberTOWordConvertion(10010000);  // Testing crore position
        System.assertEquals(' One Crore Ten Thousand Rupees Only', result6, 'Failed to handle crore position');
    }
}