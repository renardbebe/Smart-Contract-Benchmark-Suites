 

pragma solidity ^0.4.24;

 
 

contract WhatDoesNadiaThink {
    address public owner;
    string public question;
    string public questionType;
    string public answerHash;
    bytes32[] public responses;
    uint256 public marketClosureTime;
    uint256 public timeout;
    uint256 public integrityFee;
    uint256 public integrityPercentage;
    uint256 public winningAnswer;
    uint256 public total;
    
    event AddressandAnswer(address indexed _from, uint256 indexed _result, uint _value);

    constructor(string _question, bytes32[] _responses, string _questionType, string _answerHash, uint256 _timeQuestionIsOpen)
        public payable
    {
        owner = msg.sender;
        question = _question;
        responses = _responses;
        marketClosureTime = now + _timeQuestionIsOpen;  
         
         
        timeout = now + _timeQuestionIsOpen + 1209600;  
         
         
        questionType = _questionType;  
        answerHash = _answerHash;  
        integrityPercentage = 5;  
        winningAnswer = 1234;  
        total = msg.value;  
    }

    enum States { Open, Resolved, Cancelled }
    States state = States.Open;

    mapping(address => mapping(uint256 => uint256)) public answerAmount;
    mapping(uint256 => uint256) public totalPerResponse;


    uint256 winningResponse;

    function answer(uint256 result) public payable {
        
        if (now > marketClosureTime) {
            revert();  
        }
        
        require(state == States.Open);

        answerAmount[msg.sender][result] += msg.value;
        totalPerResponse[result] += msg.value;
        total += msg.value;
        require(total < 2 ** 128);    
        
        emit AddressandAnswer(msg.sender, result, msg.value);
    }

    function resolve(uint256 _winningResponse) public {
        require(now > marketClosureTime && state == States.Open);  
        require(msg.sender == owner);

        winningResponse = _winningResponse;  
        winningAnswer = winningResponse + 1;  
        
        if (totalPerResponse[winningResponse] == 0) {
            state = States.Cancelled;  
        } else {
            state = States.Resolved;
            integrityFee = total * integrityPercentage/100;  
            msg.sender.transfer(integrityFee);  
        }
        
    }

    function claim() public {
        require(state == States.Resolved);

        uint256 amount = answerAmount[msg.sender][winningResponse] * (total - integrityFee) / totalPerResponse[winningResponse];  
        answerAmount[msg.sender][winningResponse] = 0;
        msg.sender.transfer(amount);
    }

    function cancel() public {
        require(state != States.Resolved);
        require(msg.sender == owner || now > timeout);

        state = States.Cancelled;
    }

    function refund(uint256 result) public {
        require(state == States.Cancelled);

        uint256 amount = answerAmount[msg.sender][result];  
        answerAmount[msg.sender][result] = 0;
        msg.sender.transfer(amount);
    }
}