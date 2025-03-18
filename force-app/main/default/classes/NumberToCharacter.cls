/**
 *  * @author Varun Rawal

 * This class, `NumberToCharacter`, is a utility class designed to convert numeric values into their word representations.
 * It handles both whole numbers and decimal values (e.g., rupees and paisa) and is specifically tailored for Indian numbering systems
 * (e.g., lakhs, crores). The class is useful for generating textual representations of monetary values.
 *
 * Key Features:
 * - Converts numeric values into words (e.g., 1234.56 -> "One Thousand Two Hundred Thirty-Four Rupees and Fifty-Six Paisa").
 * - Handles both whole numbers and decimal parts.
 * - Supports Indian numbering conventions (e.g., lakhs, crores).
 * - Includes helper methods for reversing lists and converting digits to words.
 */

public class NumberToCharacter {

    /**
     * Converts a numeric value (including decimals) into its word representation.
     *
     * @param num The numeric value to convert (e.g., 1234.56).
     * @return The word representation of the number (e.g., "One Thousand Two Hundred Thirty-Four Rupees and Fifty-Six Paisa").
     */
    public static String getNumberTOWordConvertion(Decimal num) {
        // Separate the whole number part and the decimal (paisa) part
        Decimal junkVal = num;
        Decimal junkValPaisa = junkVal - Math.floor(junkVal); // Extract decimal part (paisa)
        junkVal = Math.floor(junkVal); // Extract whole number part

        // Convert the whole number part to a string and split into individual digits
        String obStr = junkVal.toPlainString();
        String[] numReversed = obStr.split('');
        String[] actnumber = reverse(numReversed); // Reverse the array for easier processing

        // Convert the whole number part to words
        String firstHalf = convertInWords(numReversed, actnumber);

        // Process the decimal (paisa) part
        Integer tmp = Math.round(junkValPaisa * 100); // Convert paisa to a whole number (e.g., 0.56 -> 56)
        junkValPaisa = (Decimal)tmp / 100; // Normalize back to decimal (e.g., 56 -> 0.56)
        System.debug('jj :' + junkValPaisa);

        String paisaStr = junkValPaisa.toPlainString();
        String secondHalf;

        // Handle paisa conversion
        if (paisaStr == '0') {
            secondHalf = ''; // No paisa, so no need to convert
        } else if (paisaStr.length() != 4) {
            paisaStr = paisaStr + '0'; // Pad with zero if necessary
            paisaStr = paisaStr.substring(2); // Extract the paisa part (e.g., 0.56 -> 56)
            String[] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa); // Convert paisa to words
        } else {
            paisaStr = paisaStr.substring(2); // Extract the paisa part (e.g., 0.56 -> 56)
            String[] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa); // Convert paisa to words
        }

        // Combine the whole number and paisa parts into a single string
        String SumOFHalves = '';
        if (secondHalf.length() > 4) {
            firstHalf = firstHalf.replace('Only', 'Rupees And '); // Add "Rupees And" if paisa exists
            secondHalf = secondHalf.replace('Only', 'Paisa Only'); // Add "Paisa Only" for the decimal part
            SumOFHalves = firstHalf + secondHalf;
        } else {
            firstHalf = firstHalf.replace('Only', 'Rupees Only'); // Add "Rupees Only" if no paisa
            SumOFHalves = firstHalf;
        }

        // Return the final word representation
        if (SumOFHalves.length() > 5) {
            return SumOFHalves;
        } else {
            return ''; // Return empty string if the result is invalid
        }
    }

    /**
     * Reverses a list of strings.
     *
     * @param strToRev The list of strings to reverse.
     * @return The reversed list of strings.
     */
    public static List<String> reverse(List<String> strToRev) {
        List<String> revList = new List<String>();
        for (Integer i = strToRev.size() - 1; i >= 0; i--) {
            revList.add(strToRev.get(i)); // Add elements in reverse order
        }
        revList.add(''); // Add an empty string to handle edge cases
        return revList;
    }

    /**
     * Converts a list of digits into their word representation.
     *
     * @param numRev The reversed list of digits (as strings).
     * @param actnum The actual list of digits (as strings).
     * @return The word representation of the number.
     */
    public static String convertInWords(String[] numRev, String[] actnum) {
        // Define word mappings for digits, teens, and tens
        List<String> iWords = new List<String> {'Zero', ' One', ' Two', ' Three', ' Four', ' Five', ' Six', ' Seven', ' Eight', ' Nine'};
        List<String> ePlace = new List<String> {' Ten', ' Eleven', ' Twelve', ' Thirteen', ' Fourteen', ' Fifteen', ' Sixteen', ' Seventeen', ' Eighteen', ' Nineteen'};
        List<String> tensPlace = new List<String> {'dummy', ' Ten', ' Twenty', ' Thirty', ' Forty', ' Fifty', ' Sixty', ' Seventy', ' Eighty', ' Ninety' };

        Integer iWordsLength = numRev.size();
        String totalWords = '';
        List<String> inWords = new List<String>();
        for (Integer k = 0; k < iWordsLength; k++) {
            inWords.add(''); // Initialize the list with empty strings
        }

        String finalWord = '';
        Integer j = 0;

        // Convert each digit to its word representation based on its position
        for (Integer i = 0; i < iWordsLength; i++) {
            if (i == 0) {
                // Handle units place
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Only';
            } else if (i == 1) {
                // Handle tens place
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 2) {
                // Handle hundreds place
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i - 1] != '0' && actnum[i - 2] != '0') {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred and';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred';
                }
            } else if (i == 3) {
                // Handle thousands place
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Thousand';
                }
            } else if (i == 4) {
                // Handle ten-thousands place
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 5) {
                // Handle lakhs place
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Lakh';
                }
            } else if (i == 6) {
                // Handle ten-lakhs place
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 7) {
                // Handle crores place
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Crore';
            } else if (i == 8) {
                // Handle ten-crores place
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            }
            j++;
        }

        // Reverse the list of words to get the correct order
        inWords = reverse(inWords);
        for (Integer i = 0; i < inWords.size(); i++) {
            finalWord += inWords[i]; // Combine the words into a single string
        }
        return finalWord;
    }
}