 

pragma solidity ^0.5.6;
 
  
library SafeMath{
    function mul(uint a, uint b) internal pure returns (uint){
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
 
    function div(uint a, uint b) internal pure returns (uint){
        uint c = a / b;
        return c;
    }
 
    function sub(uint a, uint b) internal pure returns (uint){
        assert(b <= a); 
        return a - b; 
    } 
  
    function add(uint a, uint b) internal pure returns (uint){ 
        uint c = a + b; assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() public{
        owner = msg.sender;
    }
 
     
   modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
     
   function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ITCMoney is Ownable{
    using SafeMath for uint;
    
    string public constant name = "ITC Money";
    string public constant symbol = "ITCM";
    uint32 public constant decimals = 18;
    
    address payable public companyAddr = address(0);
    address public constant bonusAddr   = 0xaEA6949B27C44562Dd446c2C44f403cF6D13a2fD;
    address public constant teamAddr    = 0xe0b70c54a1baa2847e210d019Bb8edc291AEA5c7;
    address public constant sellerAddr  = 0x95E1f32981F909ce39d45bF52C9108f47e0FCc50;
    
    uint public totalSupply = 0;
    uint public maxSupply = 17000000000 * 1 ether;  
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) internal allowed;
    
    bool public transferAllowed = false;
    mapping(address => bool) internal customTransferAllowed;
    
    uint public tokenRate = 170 * 1 finney;  
    uint private tokenRateDays = 0;
     
    uint[2][] private growRate = [
        [1538784000, 100],
        [1554422400,  19],
        [1564617600,  17],
        [1572566400,   0]
    ];
    
    uint public rateETHCHF = 0;
    mapping(address => uint) balancesCHF;
    bool public amountBonusAllowed = true;
     
    uint[2][] private amountBonus = [
        [uint32(2000),    500],
        [uint32(8000),    700],
        [uint32(17000),  1000],
        [uint32(50000),  1500],
        [uint32(100000), 1750],
        [uint32(150000), 2000],
        [uint32(500000), 2500]
    ];
    
     
    uint[2][] private timeBonus = [
        [1535673600, 2000],  
        [1535760000, 1800],  
        [1538784000, 1500],  
        [1541462400, 1000],  
        [1544054400,  800],  
        [1546732800,  600],  
        [1549411200,  300],  
        [1551830400,  200]   
    ];
    uint private finalTimeBonusDate = 1554508800;  
    uint public constantBonus = 0;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event CompanyChanged(address indexed previousOwner, address indexed newOwner);
    event TransfersAllowed();
    event TransfersAllowedTo(address indexed to);
    event CHFBonusStopped();
    event AddedCHF(address indexed to, uint value);
    event NewRateCHF(uint value);
    event AddedGrowPeriod(uint startTime, uint rate);
    event ConstantBonus(uint value);
    event NewTokenRate(uint tokenRate);

     
    function balanceOf(address _owner) public view returns (uint){
        return balances[_owner];
    }
 
      
    function transfer(address _to, uint _value) public returns (bool){
        require(_to != address(0));
        require(transferAllowed || _to == sellerAddr || customTransferAllowed[msg.sender]);
        require(_value > 0 && _value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true; 
    } 

      
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
        require(_to != address(0));
        require(transferAllowed || _to == sellerAddr || customTransferAllowed[_from]);
        require(_value > 0 && _value <= balances[_from] && _value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
 
     
    function approve(address _spender, uint _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
     
    function allowance(address _owner, address _spender) public view returns (uint){
        return allowed[_owner][_spender]; 
    } 
 
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true; 
    }
 
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool){
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        }else{
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function changeCompany(address payable newCompany) onlyOwner public{
        require(newCompany != address(0));
        emit CompanyChanged(companyAddr, newCompany);
        companyAddr = newCompany;
    }

     
    function allowTransfers() onlyOwner public{
        transferAllowed = true;
        emit TransfersAllowed();
    }
 
     
    function allowCustomTransfers(address _to) onlyOwner public{
        customTransferAllowed[_to] = true;
        emit TransfersAllowedTo(_to);
    }
    
     
    function stopCHFBonus() onlyOwner public{
        amountBonusAllowed = false;
        emit CHFBonusStopped();
    }
    
      
    function _mint(address _to, uint _value) private returns (bool){
         
        uint bonusAmount = _value.mul(3).div(87);
         
        uint teamAmount = _value.mul(10).div(87);
         
        uint total = _value.add(bonusAmount).add(teamAmount);
        
        require(total <= maxSupply);
        
        maxSupply = maxSupply.sub(total);
        totalSupply = totalSupply.add(total);
        
        balances[_to] = balances[_to].add(_value);
        balances[bonusAddr] = balances[bonusAddr].add(bonusAmount);
        balances[teamAddr] = balances[teamAddr].add(teamAmount);

        emit Transfer(address(0), _to, _value);
        emit Transfer(address(0), bonusAddr, bonusAmount);
        emit Transfer(address(0), teamAddr, teamAmount);

        return true;
    }

      
    function mint(address _to, uint _value) onlyOwner public returns (bool){
        return _mint(_to, _value);
    }

      
    function mint(address[] memory _to, uint[] memory _value) onlyOwner public returns (bool){
        require(_to.length == _value.length);

        uint len = _to.length;
        for(uint i = 0; i < len; i++){
            if(!_mint(_to[i], _value[i])){
                return false;
            }
        }
        return true;
    }
    
     
    function balanceCHFOf(address _owner) public view returns (uint){
        return balancesCHF[_owner];
    }

     
    function increaseCHF(address _to, uint _value) onlyOwner public{
        balancesCHF[_to] = balancesCHF[_to].add(_value);
        emit AddedCHF(_to, _value);
    }

     
    function increaseCHF(address[] memory _to, uint[] memory _value) onlyOwner public{
        require(_to.length == _value.length);

        uint len = _to.length;
        for(uint i = 0; i < len; i++){
            balancesCHF[_to[i]] = balancesCHF[_to[i]].add(_value[i]);
            emit AddedCHF(_to[i], _value[i]);
        }
    }
 
     
    function setETHCHFRate(uint _rate) onlyOwner public{
        rateETHCHF = _rate;
        emit NewRateCHF(_rate);
    }
    
     
    function addNewGrowRate(uint _startTime, uint _rate) onlyOwner public{
        growRate.push([_startTime, _rate]);
        emit AddedGrowPeriod(_startTime, _rate);
    }
 
     
    function setConstantBonus(uint _value) onlyOwner public{
        constantBonus = _value;
        emit ConstantBonus(_value);
    }

     
    function getTokenRate() public returns (uint){
        uint startTokenRate = tokenRate;
        uint totalDays = 0;
        uint len = growRate.length;
         
        for(uint i = 0; i < len; i++){
            if(now > growRate[i][0] && growRate[i][1] > 0){
                 
                uint end = now;
                if(i + 1 < len && end > growRate[i + 1][0]){
                    end = growRate[i + 1][0];
                }
                uint dateDiff = (end - growRate[i][0]) / 1 days;
                totalDays = totalDays + dateDiff;
                 
                if(dateDiff > 0 && totalDays > tokenRateDays){
                     
                     
                    for(uint ii = tokenRateDays; ii < totalDays; ii++){
                        tokenRate = tokenRate * (10000 + growRate[i][1]) / 10000;
                    }
                    tokenRateDays = totalDays;
                }
            }
        }
        if(startTokenRate != tokenRate){
            emit NewTokenRate(tokenRate);
        }
        return tokenRate;
    }
    
     
    function () external payable {
         
        require(msg.data.length == 0);
        require(msg.value > 0);
        require(rateETHCHF > 0);
        
         
        uint amount = (msg.value * rateETHCHF * 1 finney) / getTokenRate();
         
        uint amountCHF = (msg.value * rateETHCHF) / 10000 / 1 ether;
        uint totalCHF = balancesCHF[msg.sender].add(amountCHF);
        emit AddedCHF(msg.sender, amountCHF);

         
        uint len = 0;
        uint i = 0;
        uint percent = 0;
        uint bonus = 0;
        if(constantBonus > 0){
            bonus = amount.mul(constantBonus).div(10000);
        }else if(now < finalTimeBonusDate){
            len = timeBonus.length;
            percent = 0;
            for(i = 0; i < len; i++){
                if(now >= timeBonus[i][0]){
                    percent = timeBonus[i][1];
                }else{
                    break;
                }
            }
            if(percent > 0){
                bonus = amount.mul(percent).div(10000);
            }
        }

         
        if(amountBonusAllowed){
            len = amountBonus.length;
            percent = 0;
            for(i = 0; i < len; i++){
                if(totalCHF >= amountBonus[i][0]){
                    percent = amountBonus[i][1];
                }else{
                    break;
                }
            }
            if(percent > 0){
                bonus = bonus.add(amount.mul(percent).div(10000));
            }
        }
        
        amount = amount.add(bonus);
        
         
        uint bonusAmount = amount.mul(3).div(87);
         
        uint teamAmount = amount.mul(10).div(87);
         
        uint total = amount.add(bonusAmount).add(teamAmount);
        
        require(total <= maxSupply);
        
        maxSupply = maxSupply.sub(total);
        totalSupply = totalSupply.add(total);
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        balancesCHF[msg.sender] = totalCHF;
        balances[bonusAddr] = balances[bonusAddr].add(bonusAmount);
        balances[teamAddr] = balances[teamAddr].add(teamAmount);

        companyAddr.transfer(msg.value);
        
        emit Transfer(address(0), msg.sender, amount);
        emit Transfer(address(0), bonusAddr, bonusAmount);
        emit Transfer(address(0), teamAddr, teamAmount);
    }
}