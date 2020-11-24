 

pragma solidity>=0.4.22 <0.6.0;

contract EasyContract{
    
    string public word;
    
    function setWord(string memory _word)public returns(string memory){
        word = _word;
        return word;
    }
    
    
    function viewWord()public view returns(string memory){
        return word;
        
    }
    
    
}