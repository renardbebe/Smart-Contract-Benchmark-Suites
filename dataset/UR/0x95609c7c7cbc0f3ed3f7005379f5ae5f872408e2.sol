 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 

contract BnsPresale {

    string public constant VERSION = "0.2.0-bns";

     
    uint public constant PRESALE_START  = 4470000;  
    uint public constant PRESALE_END    = 5033333;  
    uint public constant WITHDRAWAL_END = 5111111;  

    address public constant OWNER = 0x54ef8Ffc6EcdA95d286722c0358ad79123c3c8B0;

    uint public constant MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH = 0;
    uint public constant MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH = 3125;
    uint public constant MIN_ACCEPTED_AMOUNT_FINNEY = 1;

     

    string[5] private stateNames = ["BEFORE_START",  "PRESALE_RUNNING", "WITHDRAWAL_RUNNING", "REFUND_RUNNING", "CLOSED" ];
    enum State { BEFORE_START,  PRESALE_RUNNING, WITHDRAWAL_RUNNING, REFUND_RUNNING, CLOSED }

    uint public total_received_amount;
    uint public total_refunded;
    mapping (address => uint) public balances;

    uint private constant MIN_TOTAL_AMOUNT_TO_RECEIVE = MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MAX_TOTAL_AMOUNT_TO_RECEIVE = MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MIN_ACCEPTED_AMOUNT = MIN_ACCEPTED_AMOUNT_FINNEY * 1 finney;
    bool public isAborted = false;
    bool public isStopped = false;


     
    function BnsPresale () public validSetupOnly() { }

     
     
     

     
    function ()
    payable
    noReentrancy
    public
    {
        State state = currentState();
        if (state == State.PRESALE_RUNNING) {
            receiveFunds();
        } else if (state == State.REFUND_RUNNING) {
             
            sendRefund();
        } else {
            revert();
        }
    }

    function refund() external
    inState(State.REFUND_RUNNING)
    noReentrancy
    {
        sendRefund();
    }


    function withdrawFunds() external
    onlyOwner
    noReentrancy
    {
         
        OWNER.transfer(this.balance);
    }


    function abort() external
    inStateBefore(State.REFUND_RUNNING)
    onlyOwner
    {
        isAborted = true;
    }


    function stop() external
    inState(State.PRESALE_RUNNING)
    onlyOwner
    {
        isStopped = true;
    }


     
    function state() external constant
    returns (string)
    {
        return stateNames[ uint(currentState()) ];
    }


     
     
     

    function sendRefund() private tokenHoldersOnly {
         
        uint amount_to_refund = min(balances[msg.sender], this.balance - msg.value) ;

         
        balances[msg.sender] -= amount_to_refund;
        total_refunded += amount_to_refund;

         
        msg.sender.transfer(amount_to_refund + msg.value);
    }


    function receiveFunds() private notTooSmallAmountOnly {
       
      if (total_received_amount + msg.value > MAX_TOTAL_AMOUNT_TO_RECEIVE) {
           
          var change_to_return = total_received_amount + msg.value - MAX_TOTAL_AMOUNT_TO_RECEIVE;
          var acceptable_remainder = MAX_TOTAL_AMOUNT_TO_RECEIVE - total_received_amount;
          balances[msg.sender] += acceptable_remainder;
          total_received_amount += acceptable_remainder;

          msg.sender.transfer(change_to_return);
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
        } else if (block.number <= PRESALE_END && total_received_amount < MAX_TOTAL_AMOUNT_TO_RECEIVE && !isStopped) {
            return State.PRESALE_RUNNING;
        } else if (this.balance == 0) {
            return State.CLOSED;
        } else if (block.number <= WITHDRAWAL_END && total_received_amount >= MIN_TOTAL_AMOUNT_TO_RECEIVE) {
            return State.WITHDRAWAL_RUNNING;
        } else {
            return State.REFUND_RUNNING;
        }
    }

    function min(uint a, uint b) pure private returns (uint) {
        return a < b ? a : b;
    }


     
     
     

     
    modifier inState(State state) {
        assert(state == currentState());
        _;
    }

     
    modifier inStateBefore(State state) {
        assert(currentState() < state);
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
                revert();
        _;
    }


     
    modifier onlyOwner(){
        assert(msg.sender == OWNER);
        _;
    }


     
    modifier tokenHoldersOnly(){
        assert(balances[msg.sender] > 0);
        _;
    }


     
    modifier notTooSmallAmountOnly(){
        assert(msg.value >= MIN_ACCEPTED_AMOUNT);
        _;
    }


     
    bool private locked = false;
    modifier noReentrancy() {
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }
} 