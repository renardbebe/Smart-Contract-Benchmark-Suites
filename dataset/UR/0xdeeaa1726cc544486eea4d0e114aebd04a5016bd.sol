 

pragma solidity ^0.5.8;

contract IBNEST {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
    
    function balancesStart() public view returns(uint256);
    function balancesGetBool(uint256 num) public view returns(bool);
    function balancesGetNext(uint256 num) public view returns(uint256);
    function balancesGetValue(uint256 num) public view returns(address, uint256);
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b > 0);  
    uint256 c = _a / _b;
    assert(_a == _b * c + _a % _b);  
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract IBMapping {
     
	function checkAddress(string memory name) public view returns (address contractAddress);
	 
	function checkOwners(address man) public view returns (bool);
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract NESTSave {
    function takeOut(uint256 num) public;
    function depositIn(uint256 num) public;
    function takeOutPrivate() public;
    function checkAmount(address sender) public view returns(uint256);
}

contract Abonus {
    function getETH(uint256 num) public;    
    function getETHNum() public view returns (uint256);
}

contract NESTAbonus {
    using address_make_payable for address;
    using SafeMath for uint256;
    IBNEST nestContract;
    IBMapping mappingContract;                  
    NESTSave baseMapping;
    Abonus abonusContract;
    
    uint256 timeLimit = 168 hours;                    
    uint256 nextTime = 1562299200;                   
    uint256 getAbonusTimeLimit = 60 hours;           
    
    uint256 ethNum = 0;                         
    uint256 nestAllValue = 0;                   
    uint256 times = 0;                          
    
    mapping(uint256 => mapping(address => bool)) getMapping;
    constructor (address map) public {
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        baseMapping = NESTSave(address(mappingContract.checkAddress("nestSave")));
        address payable addr = address(mappingContract.checkAddress("abonus")).make_payable();
        abonusContract = Abonus(addr);
    }

    function changeMapping(address map) public {
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        baseMapping = NESTSave(address(mappingContract.checkAddress("nestSave")));
        address payable addr = address(mappingContract.checkAddress("abonus")).make_payable();
        abonusContract = Abonus(addr);
    }
    
    function depositIn(uint256 amount) public {
        require(isContract(address(msg.sender)) == false);          
        uint256 nowTime = now;
        if (nowTime < nextTime) {
            require(!(nowTime >= nextTime.sub(timeLimit) && nowTime <= nextTime.sub(timeLimit).add(getAbonusTimeLimit)));
        } else {
            require(!(nowTime >= nextTime && nowTime <= nextTime.add(getAbonusTimeLimit)));
            uint256 time = (nowTime.sub(nextTime)).div(timeLimit);
            uint256 startTime = nextTime.add((time).mul(timeLimit));         
            uint256 endTime = startTime.add(getAbonusTimeLimit);                     
            require(!(nowTime >= startTime && nowTime <= endTime));
        }
        baseMapping.depositIn(amount);                              
    }
    
    function takeOut(uint256 amount) public {
        require(isContract(address(msg.sender)) == false);          
        require(amount != 0);                                       
        require(amount <= baseMapping.checkAmount(address(msg.sender)));
        baseMapping.takeOut(amount);                         
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    
    function getETH() public {
        require(isContract(address(msg.sender)) == false);          
        reloadTimeAndMapping ();                
        uint256 nowTime = now;
        require(nowTime >= nextTime.sub(timeLimit) && nowTime <= nextTime.sub(timeLimit).add(getAbonusTimeLimit));
        require(getMapping[times.sub(1)][address(msg.sender)] != true);     
        uint256 nestAmount = baseMapping.checkAmount(address(msg.sender));
        require(nestAmount > 0);
        require(nestAllValue > 0);
        uint256 selfEth = nestAmount.mul(ethNum).div(nestAllValue);
        require(selfEth > 0);
        
        getMapping[times.sub(1)][address(msg.sender)] = true;
        abonusContract.getETH(selfEth);                           
    }
    
    function reloadTimeAndMapping () private {
        require(isContract(address(msg.sender)) == false);          
        uint256 nowTime = now;
        if (nowTime >= nextTime) {                                                      
            uint256 time = (nowTime.sub(nextTime)).div(timeLimit);
            uint256 startTime = nextTime.add((time).mul(timeLimit));         
            uint256 endTime = startTime.add(getAbonusTimeLimit);                     
            if (nowTime >= startTime && nowTime <= endTime) {
                nextTime = getNextTime();                               
                times = times.add(1);                                   
                ethNum = abonusContract.getETHNum();                    
                nestAllValue = allValue();                              
            }
        }
    }
    
    function getInfo() public view returns (uint256 _nextTime, uint256 _getAbonusTime, uint256 _ethNum, uint256 _nestValue, uint256 _myJoinNest, uint256 _getEth, uint256 _allowNum, uint256 _leftNum, bool allowAbonus)  {
        uint256 nowTime = now;
        if (nowTime >= nextTime.sub(timeLimit) && nowTime <= nextTime.sub(timeLimit).add(getAbonusTimeLimit)) {
            allowAbonus = getMapping[times.sub(1)][address(msg.sender)];
            _ethNum = ethNum;
            _nestValue = nestAllValue;
            
        } else {
            _ethNum = abonusContract.getETHNum();
            _nestValue = allValue();
            allowAbonus = getMapping[times][address(msg.sender)];
        }
        _myJoinNest = baseMapping.checkAmount(address(msg.sender));
        if (allowAbonus == true) {
            _getEth = 0; 
        } else {
            _getEth = _myJoinNest.mul(_ethNum).div(_nestValue);
        }
        
       
        _nextTime = getNextTime();
        _getAbonusTime = _nextTime.sub(timeLimit).add(getAbonusTimeLimit);
        _allowNum = nestContract.allowance(address(msg.sender), address(baseMapping));
        _leftNum = nestContract.balanceOf(address(msg.sender));
        
    }
    
    function getNextTime() public view returns (uint256) {
        uint256 nowTime = now;
        if (nextTime >= nowTime) { 
            return nextTime; 
        } else {
            uint256 time = (nowTime.sub(nextTime)).div(timeLimit);
            return nextTime.add(timeLimit.mul(time.add(1)));
        }
    }
    
    function allValue() public view returns (uint256) {
        uint256 all = 10000000000 ether;
        uint256 leftNum = all.sub(nestContract.balanceOf(address(mappingContract.checkAddress("miningSave"))));
        return leftNum;
    }
    function changeTimeLimit(uint256 hour) public onlyOwner {
        require(hour > 0);
        timeLimit = hour.mul(1 hours);
    }

    function changeGetAbonusTimeLimit(uint256 hour) public onlyOwner {
        require(hour > 0);
        getAbonusTimeLimit = hour;
    }

    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}