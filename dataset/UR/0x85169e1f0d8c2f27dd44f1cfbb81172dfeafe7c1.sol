 

pragma solidity ^0.4.6;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 

contract Presale {

    string public constant VERSION = "0.1.4-beta";

     

    uint public constant PRESALE_START  = 3142163;  
    uint public constant PRESALE_END    = 3145693;  
    uint public constant WITHDRAWAL_END = 3151453;  


    address public constant OWNER = 0x45d5426471D12b21C3326dD0cF96f6656F7d14b1;

    uint public constant MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH = 1;
    uint public constant MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH = 5;
    uint public constant MIN_ACCEPTED_AMOUNT_FINNEY = 1;

     

    string[5] private stateNames = ["BEFORE_START",  "PRESALE_RUNNING", "WITHDRAWAL_RUNNING", "REFUND_RUNNING", "CLOSED" ];
    enum State { BEFORE_START,  PRESALE_RUNNING, WITHDRAWAL_RUNNING, REFUND_RUNNING, CLOSED }

    uint public total_received_amount;
    mapping (address => uint) public balances;

    uint private constant MIN_TOTAL_AMOUNT_TO_RECEIVE = MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MAX_TOTAL_AMOUNT_TO_RECEIVE = MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MIN_ACCEPTED_AMOUNT = MIN_ACCEPTED_AMOUNT_FINNEY * 1 finney;
    bool public isAborted = false;


     
    function Presale () validSetupOnly() { }

     
     
     

     
    function ()
    payable
    noReentrancy
    {
        State state = currentState();
        if (state == State.PRESALE_RUNNING) {
            receiveFunds();
        } else if (state == State.REFUND_RUNNING) {
             
            sendRefund();
        } else {
            throw;
        }
    }

    function refund() external
    inState(State.REFUND_RUNNING)
    noReentrancy
    {
        sendRefund();
    }


    function withdrawFunds() external
    inState(State.WITHDRAWAL_RUNNING)
    onlyOwner
    noReentrancy
    {
         
        if (!OWNER.send(this.balance)) throw;
    }

    function abort() external
    inStateBefore(State.REFUND_RUNNING)
    onlyOwner
    {
        isAborted = true;
    }

     
    function state()  external constant
    returns (string)
    {
        return stateNames[ uint(currentState()) ];
    }


     
     
     

    function sendRefund() private tokenHoldersOnly {
         
        var amount_to_refund = balances[msg.sender] + msg.value;
         
        balances[msg.sender] = 0;
         
        if (!msg.sender.send(amount_to_refund)) throw;
    }


    function receiveFunds() private notTooSmallAmountOnly {
       
      if (total_received_amount + msg.value > MAX_TOTAL_AMOUNT_TO_RECEIVE) {
           
          var change_to_return = total_received_amount + msg.value - MAX_TOTAL_AMOUNT_TO_RECEIVE;
          if (!msg.sender.send(change_to_return)) throw;

          var acceptable_remainder = MAX_TOTAL_AMOUNT_TO_RECEIVE - total_received_amount;
          balances[msg.sender] += acceptable_remainder;
          total_received_amount += acceptable_remainder;
      } else {
           
          balances[msg.sender] += msg.value;
          total_received_amount += msg.value;
      }
    }


    function currentState() private constant returns (State) {
        if (isAborted) {
            return this.balance > 0 
                   ? State.REFUND_RUNNING 
                   : State.CLOSED;
        } else if (block.number < PRESALE_START) {
            return State.BEFORE_START;
        } else if (block.number <= PRESALE_END && total_received_amount < MAX_TOTAL_AMOUNT_TO_RECEIVE) {
            return State.PRESALE_RUNNING;
        } else if (this.balance == 0) {
            return State.CLOSED;
        } else if (block.number <= WITHDRAWAL_END && total_received_amount >= MIN_TOTAL_AMOUNT_TO_RECEIVE) {
            return State.WITHDRAWAL_RUNNING;
        } else {
            return State.REFUND_RUNNING;
        } 
    }

     
     
     

     
    modifier inState(State state) {
        if (state != currentState()) throw;
        _;
    }

     
    modifier inStateBefore(State state) {
        if (currentState() >= state) throw;
        _;
    }

     
    modifier validSetupOnly() {
        if ( OWNER == 0x0 
            || PRESALE_START == 0 
            || PRESALE_END == 0 
            || WITHDRAWAL_END ==0
            || PRESALE_START <= block.number
            || PRESALE_START >= PRESALE_END
            || PRESALE_END   >= WITHDRAWAL_END
            || MIN_TOTAL_AMOUNT_TO_RECEIVE > MAX_TOTAL_AMOUNT_TO_RECEIVE )
                throw;
        _;
    }


     
    modifier onlyOwner(){
        if (msg.sender != OWNER)  throw;
        _;
    }


     
    modifier tokenHoldersOnly(){
        if (balances[msg.sender] == 0) throw;
        _;
    }


     
    modifier notTooSmallAmountOnly(){	
        if (msg.value < MIN_ACCEPTED_AMOUNT) throw;
        _;
    }


     
    bool private locked = false;
    modifier noReentrancy() {
        if (locked) throw;
        locked = true;
        _;
        locked = false;
    }
} 