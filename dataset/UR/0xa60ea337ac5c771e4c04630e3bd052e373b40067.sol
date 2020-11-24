 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
 
 
 





 
 
contract Fundraiser {
    using SafeMath for uint;

     
    uint public constant dust = 100 finney;

     
     
     
    address public admin;
    address public treasury;

     
     
     

     
    uint public weiPerBtc;

     
    uint public EtmPerBtc;

     
    bool public isHalted = false;

     
    mapping (address => uint) public records;

     
    uint public totalWei = 0;
     
    uint public totalETM = 0;
     
    uint public numDonations = 0;

     
     
     
     
    function Fundraiser(
        address _admin,
        address _treasury,
         
         
        uint _weiPerBtc,
        uint _EtmPerBtc
    ) {
        require(_weiPerBtc > 0);
        require(_EtmPerBtc > 0);

        admin = _admin;
        treasury = _treasury;
         
         

        weiPerBtc = _weiPerBtc;
        EtmPerBtc = _EtmPerBtc;
    }

     
    modifier only_admin { require(msg.sender == admin); _; }
     
     
     
    modifier only_during_period { require( !isHalted); _; }
     
    modifier only_during_halted_period { require( isHalted); _; }
     
     
     
    modifier is_not_dust { require(msg.value >= dust); _; }

     
    event Received(address indexed recipient, address returnAddr, uint weiAmount, uint currentRate);
     
    event Halted();
     
    event Unhalted();
    event RateChanged(uint newRate);

     
    function isActive() public constant returns (bool active) {
        return (  !isHalted);
    }

     
    function donate(address _donor, address _returnAddress, bytes4 checksum) public payable only_during_period is_not_dust {
         
        require( bytes4(sha3( bytes32(_donor)^bytes32(_returnAddress) )) == checksum );

         
        require( treasury.send(msg.value) );

         
        uint weiPerETM = weiPerBtc.div(EtmPerBtc);
        uint ETM = msg.value.div(weiPerETM);

         
        records[_donor] = records[_donor].add(ETM);

         
        totalWei = totalWei.add(msg.value);
        totalETM = totalETM.add(ETM);
        numDonations = numDonations.add(1);

        Received(_donor, _returnAddress, msg.value, weiPerETM);
    }

     
    function adjustRate(uint newRate) public only_admin {
        weiPerBtc = newRate;
        RateChanged(newRate);
    }

     
    function halt() public only_admin only_during_period {
        isHalted = true;
        Halted();
    }

     
    function unhalt() public only_admin only_during_halted_period {
        isHalted = false;
        Unhalted();
    }

     
    function kill() public only_admin   {
        suicide(treasury);
    }
}