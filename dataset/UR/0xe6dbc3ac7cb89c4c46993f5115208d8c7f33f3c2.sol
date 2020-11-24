 

pragma solidity ^0.4.19;

 

contract WordCloud {
  address guyWhoGetsPaid = msg.sender;
  mapping (string => uint) wordSizes;
  event WordSizeIncreased(string word, uint newSize);

  function increaseWordSize(string word) external payable {
    wordSizes[word] += msg.value;
    guyWhoGetsPaid.transfer(this.balance);
    WordSizeIncreased(word, wordSizes[word]);
  }

  function wordSize(string word) external view returns (uint) {
    return wordSizes[word];
  }
}