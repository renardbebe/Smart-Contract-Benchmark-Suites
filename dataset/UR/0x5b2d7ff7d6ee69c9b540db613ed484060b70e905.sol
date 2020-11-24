 

pragma solidity ^0.4.19;

 
contract PreIcoContract {
    function buyTokens (address _investor) public payable;
    uint256 public startTime;
    uint256 public endTime;
}

 
contract ReservationContract {

     
    mapping(address => bool) public invested;
     
    uint public MIN_INVESTMENT = 1 ether;
     
    PreIcoContract public preIcoAddr;
     
    uint public preIcoStart;
    uint public preIcoEnd;

     
    function ReservationContract(address _preIcoAddr) public {
        require(_preIcoAddr != 0x0);
        require(isContract(_preIcoAddr) == true);

         
        preIcoAddr = PreIcoContract(_preIcoAddr);

         
        preIcoStart = preIcoAddr.startTime();
        preIcoEnd = preIcoAddr.endTime();
        require(preIcoStart != 0 && preIcoEnd != 0 && now <= preIcoEnd);
    }

     
    function() public payable {
        require(msg.value >= MIN_INVESTMENT);
        require(now >= preIcoStart && now <= preIcoEnd);
         
        require(isContract(msg.sender) == false);

         
        if (invested[msg.sender] == false) {
            invested[msg.sender] = true;
        }

         
        preIcoAddr.buyTokens.value(msg.value)(msg.sender);
    }

     
    function isContract(address addr) public constant returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}