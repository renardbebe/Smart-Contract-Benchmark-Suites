 

pragma solidity 0.4.25;



interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool ok);
    function transferFrom(address from, address to, uint256 value) external returns (bool ok);
    function approve(address spender, uint256 value) external returns (bool ok);  
    function totalSupply() external view returns(uint256);
}
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
contract Ownable {    
    address public owner;
    address public tempOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferRequest(address indexed previousOwner, address indexed newOwner);
    
     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferRequest(owner, newOwner);
        tempOwner = newOwner;
    }
  
     
    function acceptOwnership() public {  
        require(tempOwner==msg.sender);
        emit OwnershipTransferred(owner,msg.sender);
        owner = msg.sender;
    }
}



 
contract HITT is ERC20,Ownable {    
    using SafeMath for uint256;
    string public constant name = "Health Information Transfer Token";
    string public constant symbol = "HITT";
    uint8 public constant decimals = 18;
    uint256 private constant totalSupply1 = 1000000000 * 10 ** uint256(decimals);
    address[] public founders = [
        0x89Aa30ca3572eB725e5CCdcf39d44BAeD5179560, 
        0x1c61461794df20b0Ed8C8D6424Fd7B312722181f];
    address[] public advisors = [
        0xc83eDeC2a4b6A992d8fcC92484A82bC312E885B5, 
        0x9346e8A0C76825Cd95BC3679ab83882Fd66448Ab, 
        0x3AA2958c7799faAEEbE446EE5a5D90057fB5552d, 
        0xF90f4D2B389D499669f62F3a6F5E0701DFC202aF, 
        0x45fF9053b44914Eedc90432c3B6674acDD400Cf1, 
        0x663070ab83fEA900CB7DCE7c92fb44bA9E0748DE];
    mapping (address => uint256)  balances;
    mapping (address => mapping (address => uint256))  allowed;
    mapping (address => uint64) lockTimes;
    
     
    uint64 public constant tokenLockTime = 31104000;
    
     
    uint256 public constant hodlerPoolTokens = 15000000 * 10 ** uint256(decimals) ; 
    Hodler public hodlerContract;

     
    constructor() public {
        uint8 i=0 ;
        balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6] = totalSupply1;
        emit Transfer(0x0,0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6,totalSupply1);
        uint256 length = founders.length ;
        for( ; i < length ; i++ ){
             
            lockTimes[founders[i]] = uint64(block.timestamp + 365 days + tokenLockTime );
        }
        length = advisors.length ;
        for( i=0 ; i < length ; i++ ){
            lockTimes[advisors[i]] = uint64(block.timestamp +  365 days + tokenLockTime); 
            balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6] = balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6].sub(40000 * 10 ** uint256(decimals));
            balances[advisors[i]] = 40000 * 10 ** uint256(decimals) ;
            emit Transfer( 0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6, advisors[i], 40000 * 10 ** uint256(decimals) );
        }
        balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6] = balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6].sub(130000000 * 10 ** uint256(decimals));
        balances[founders[0]] = 100000000 * 10 ** uint256(decimals) ;
        balances[founders[1]] =  30000000 * 10 ** uint256(decimals) ; 
        emit Transfer( 0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6, founders[0], 100000000 * 10 ** uint256(decimals) );
        emit Transfer( 0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6, founders[1],  30000000 * 10 ** uint256(decimals) );
        hodlerContract = new Hodler(hodlerPoolTokens, msg.sender); 
        balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6] = balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6].sub(hodlerPoolTokens);
        balances[address(hodlerContract)] = hodlerPoolTokens;  
        assert(totalSupply1 == balances[0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6].add(hodlerPoolTokens.add((130000000 * 10 ** uint256(decimals)).add(length.mul(40000 * 10 ** uint256(decimals))))));
        emit Transfer( 0x60Bf75BB47cbD4cD1eeC7Cd48eab1F16Ebe822c6, address(hodlerContract), hodlerPoolTokens );
    }
    

     
    function totalSupply() public view returns(uint256) {
        return totalSupply1;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(!isContract(_to));
        require(block.timestamp > lockTimes[_from]);
        uint256 prevBalTo = balances[_to] ;
        uint256 prevBalFrom = balances[_from];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(hodlerContract.isValid(_from)) {
            require(hodlerContract.invalidate(_from));
        }
        emit Transfer(_from, _to, _value);
        assert(_value == balances[_to].sub(prevBalTo));
        assert(_value == prevBalFrom.sub(balances[_from]));
        return true;
    }
	
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]); 
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(block.timestamp>lockTimes[msg.sender]);
        allowed[msg.sender][_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function saleDistributionMultiAddress(address[] _addresses,uint256[] _values) public onlyOwner returns (bool) {    
        require( _addresses.length > 0 && _addresses.length == _values.length); 
        uint256 length = _addresses.length ;
        for(uint8 i=0 ; i < length ; i++ )
        {
            if(_addresses[i] != address(0) && _addresses[i] != owner) {
                require(hodlerContract.addHodlerStake(_addresses[i], _values[i]));
                _transfer( msg.sender, _addresses[i], _values[i]) ;
            }
        }
        return true;
    }
     
     
    function batchTransfer(address[] _addresses,uint256[] _values) public  returns (bool) {    
        require(_addresses.length > 0 && _addresses.length == _values.length);
        uint256 length = _addresses.length ;
        for( uint8 i = 0 ; i < length ; i++ ){
            
            if(_addresses[i] != address(0)) {
                _transfer(msg.sender, _addresses[i], _values[i]);
            }
        }
        return true;
    }   
    
     
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    
}


contract Hodler is Ownable {
    using SafeMath for uint256;
    bool istransferringTokens = false;
    address public admin;  
    
     
    struct HODL {
        uint256 stake;
        bool claimed3M;
        bool claimed6M;
        bool claimed9M;
        bool claimed12M;
    }

    mapping (address => HODL) public hodlerStakes;

     
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;

     
    uint256 public hodlerTotalValue3M;
    uint256 public hodlerTotalValue6M;
    uint256 public hodlerTotalValue9M;
    uint256 public hodlerTotalValue12M;

     
    uint256 public hodlerTimeStart;
 
     
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;
    uint256 public TOKEN_HODL_12M;

     
    uint256 public claimedTokens;
    
    event LogHodlSetStake(address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _beneficiary, uint256 _value);

    ERC20 public tokenContract;
    
     
    modifier beforeHodlStart() {
        require(block.timestamp < hodlerTimeStart);
        _;
    }

     
    constructor(uint256 _stake, address _admin) public {
        TOKEN_HODL_3M = (_stake*75)/1000;
        TOKEN_HODL_6M = (_stake*15)/100;
        TOKEN_HODL_9M = (_stake*30)/100;
        TOKEN_HODL_12M = (_stake*475)/1000;
        tokenContract = ERC20(msg.sender);
        hodlerTimeStart = block.timestamp.add(365 days) ;  
        admin = _admin;
    }
    
     
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart returns (bool) {
         
        if (_stake == 0 || _beneficiary == address(0))
            return false;
        
         
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);
        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);
        hodlerTotalValue = hodlerTotalValue.add(_stake);
        emit LogHodlSetStake(_beneficiary, hodlerStakes[_beneficiary].stake);
        return true;
    }
   
      
    function invalidate(address _account) public onlyOwner returns (bool) {
        if (hodlerStakes[_account].stake > 0 ) {
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake); 
            hodlerTotalCount = hodlerTotalCount.sub(1);
            updateAndGetHodlTotalValue();
            delete hodlerStakes[_account];
            return true;
        }
        return false;
    }

     
    function isValid(address _account) view public returns (bool) {
        if (hodlerStakes[_account].stake > 0) {
            return true;
        }
        return false;
    }
    
     
    function claimHodlRewardFor(address _beneficiary) public returns (bool) {
        require(block.timestamp.sub(hodlerTimeStart)<= 450 days ); 
         
        require(hodlerStakes[_beneficiary].stake > 0);
        updateAndGetHodlTotalValue();
        uint256 _stake = calculateStake(_beneficiary);
        if (_stake > 0) {
            if (istransferringTokens == false) {
             
            claimedTokens = claimedTokens.add(_stake);
                istransferringTokens = true;
             
            require(tokenContract.transfer(_beneficiary, _stake));
                istransferringTokens = false ;
            emit LogHodlClaimed(_beneficiary, _stake);
            return true;
            }
        } 
        return false;
    }

     
    function calculateStake(address _beneficiary) internal returns (uint256) {
        uint256 _stake = 0;
                
        HODL memory hodler = hodlerStakes[_beneficiary];
        
        if(( hodler.claimed3M == false ) && ( block.timestamp.sub(hodlerTimeStart)) >= 90 days){ 
            _stake = _stake.add(hodler.stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue3M));
            hodler.claimed3M = true;
        }
        if(( hodler.claimed6M == false ) && ( block.timestamp.sub(hodlerTimeStart)) >= 180 days){ 
            _stake = _stake.add(hodler.stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue6M));
            hodler.claimed6M = true;
        }
        if(( hodler.claimed9M == false ) && ( block.timestamp.sub(hodlerTimeStart)) >= 270 days ){ 
            _stake = _stake.add(hodler.stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue9M));
            hodler.claimed9M = true;
        }
        if(( hodler.claimed12M == false ) && ( block.timestamp.sub(hodlerTimeStart)) >= 360 days){ 
            _stake = _stake.add(hodler.stake.mul(TOKEN_HODL_12M).div(hodlerTotalValue12M));
            hodler.claimed12M = true;
        }
        
        hodlerStakes[_beneficiary] = hodler;
        return _stake;
    }
    
     
    function finalizeHodler() public returns (bool) {
        require(msg.sender == admin);
        require(block.timestamp >= hodlerTimeStart.add( 450 days ) ); 
        uint256 amount = tokenContract.balanceOf(this);
        require(amount > 0);
        if (istransferringTokens == false) {
            istransferringTokens = true;
            require(tokenContract.transfer(admin,amount));
            istransferringTokens = false;
            return true;
        }
        return false;
    }
    
    

     
    function claimHodlRewardsForMultipleAddresses(address[] _beneficiaries) external returns (bool) {
        require(block.timestamp.sub(hodlerTimeStart) <= 450 days ); 
        uint8 length = uint8(_beneficiaries.length);
        for (uint8 i = 0; i < length ; i++) {
            if(hodlerStakes[_beneficiaries[i]].stake > 0 && (hodlerStakes[_beneficiaries[i]].claimed3M == false || hodlerStakes[_beneficiaries[i]].claimed6M == false || hodlerStakes[_beneficiaries[i]].claimed9M == false || hodlerStakes[_beneficiaries[i]].claimed12M == false)) { 
                require(claimHodlRewardFor(_beneficiaries[i]));
            }
        }
        return true;
    }
    
     
    function updateAndGetHodlTotalValue() public returns (uint) {
        if (block.timestamp >= hodlerTimeStart+ 90 days && hodlerTotalValue3M == 0) {   
            hodlerTotalValue3M = hodlerTotalValue;
        }

        if (block.timestamp >= hodlerTimeStart+ 180 days && hodlerTotalValue6M == 0) { 
            hodlerTotalValue6M = hodlerTotalValue;
        }

        if (block.timestamp >= hodlerTimeStart+ 270 days && hodlerTotalValue9M == 0) { 
            hodlerTotalValue9M = hodlerTotalValue;
        }
        if (block.timestamp >= hodlerTimeStart+ 360 days && hodlerTotalValue12M == 0) { 
            hodlerTotalValue12M = hodlerTotalValue;
        }

        return hodlerTotalValue;
    }
}