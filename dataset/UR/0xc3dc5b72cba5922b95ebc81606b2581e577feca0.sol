 

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender == owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "address(0) != _newOwner");
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "msg.sender == newOwner");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
}

contract Adminable is Ownable {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender] && msg.sender != owner, "admins[msg.sender] && msg.sender != owner");
        _;
    }

    function setAdmin(address _admin, bool _authorization) public onlyOwner {
        admins[_admin] = _authorization;
    }
 
}


contract Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    uint8 public decimals;
}

contract TokedoExchange is Ownable, Adminable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public invalidOrder;

    function invalidateOrdersBefore(address _user) public onlyAdmin {
        require(now > invalidOrder[_user], "now > invalidOrder[_user]");
        invalidOrder[_user] = now;
    }

    mapping (address => mapping (address => uint256)) public tokens;  
    

    mapping (address => uint256) public lastActiveTransaction;  
    mapping (bytes32 => uint256) public orderFills;  
    
    address public feeAccount;
    uint256 public inactivityReleasePeriod = 2 weeks;
    
    mapping (bytes32 => bool) public hashed;  

    
    uint256 public constant maxFeeWithdrawal = 0.05 ether;  
    uint256 public constant maxFeeTrade = 0.10 ether;  
    
    address public tokedoToken;
    uint256 public tokedoTokenFeeDiscount;
    
    mapping (address => bool) public baseCurrency;
    
    constructor(address _feeAccount, address _tokedoToken, uint256 _tokedoTokenFeeDiscount) public {
        feeAccount = _feeAccount;
        tokedoToken = _tokedoToken;
        tokedoTokenFeeDiscount = _tokedoTokenFeeDiscount;
    }
    
     
    
    function setInactivityReleasePeriod(uint256 _expiry) public onlyAdmin returns (bool success) {
        require(_expiry < 26 weeks, "_expiry < 26 weeks");
        inactivityReleasePeriod = _expiry;
        return true;
    }
    
    function setFeeAccount(address _newFeeAccount) public onlyOwner returns (bool success) {
        feeAccount = _newFeeAccount;
        success = true;
    }
    
    function setTokedoToken(address _tokedoToken) public onlyOwner returns (bool success) {
        tokedoToken = _tokedoToken;
        success = true;
    }
    
    function setTokedoTokenFeeDiscount(uint256 _tokedoTokenFeeDiscount) public onlyOwner returns (bool success) {
        tokedoTokenFeeDiscount = _tokedoTokenFeeDiscount;
        success = true;
    }
    
    function setBaseCurrency (address _baseCurrency, bool _boolean) public onlyOwner returns (bool success) {
        baseCurrency[_baseCurrency] = _boolean;
        success = true;
    }
    
     
    function updateAccountActivity() public {
        lastActiveTransaction[msg.sender] = now;
    }
     
    function adminUpdateAccountActivity(address _user, uint256 _expiry, uint8 _v, bytes32 _r, bytes32 _s)
    public onlyAdmin returns(bool success) {
        require(now < _expiry, "should be: now < _expiry");
        bytes32 hash = keccak256(abi.encodePacked(this, _user, _expiry));
        require(!hashed[hash], "!hashed[hash]");
        hashed[hash] = true;
        
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == _user,"invalid update account activity signature");
       
        lastActiveTransaction[_user] = now;
        success = true;
    }
     
     
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    
    function tokenFallback(address _from, uint256 _amount, bytes) public returns(bool) {
        depositTokenFunction(msg.sender, _amount, _from);
        return true;
    }

    function receiveApproval(address _from, uint256 _amount, bytes) public returns(bool) {
        transferFromAndDepositTokenFunction(msg.sender, _amount, _from, _from);
        return true;
    }
    
    function depositToken(address _token, uint256 _amount) public returns(bool) {
        transferFromAndDepositTokenFunction(_token, _amount, msg.sender, msg.sender);
        return true;
    }
    
    function depositTokenFor(address _token, uint256 _amount, address _beneficiary) public returns(bool) {
        transferFromAndDepositTokenFunction(_token, _amount, msg.sender, _beneficiary);
        return true;
    }

    function transferFromAndDepositTokenFunction (address _token, uint256 _amount, address _sender, address _beneficiary) private {
        require(Token(_token).transferFrom(_sender, this, _amount), "Token(_token).transferFrom(_sender, this, _amount)");
        depositTokenFunction(_token, _amount, _beneficiary);
    }

    function depositTokenFunction(address _token, uint256 _amount, address _beneficiary) private {
        tokens[_token][_beneficiary] = tokens[_token][_beneficiary].add(_amount);
        
        if(tx.origin == _beneficiary) lastActiveTransaction[tx.origin] = now;
        
        emit Deposit(_token, _beneficiary, _amount, tokens[_token][_beneficiary]);
    }
    
     

    function depositEther() public payable {
        depositEtherFor(msg.sender);
    }
    
    function depositEtherFor(address _beneficiary) public payable {
        tokens[address(0)][_beneficiary] = tokens[address(0)][_beneficiary].add(msg.value);
        
        if(msg.sender == _beneficiary) lastActiveTransaction[msg.sender] = now;
        
        emit Deposit(address(0), _beneficiary, msg.value, tokens[address(0)][_beneficiary]);
    }

     
    event EmergencyWithdraw(address token, address user, uint256 amount, uint256 balance);

    function emergencyWithdraw(address _token, uint256 _amount) public returns (bool success) {
        
        require(now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod, "now.sub(lastActiveTransaction[msg.sender]) > inactivityReleasePeriod");
        require(tokens[_token][msg.sender] >= _amount, "not enough balance for withdrawal");
        
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        
        if (_token == address(0)) {
            require(msg.sender.send(_amount), "msg.sender.send(_amount)");
        } else {
            require(Token(_token).transfer(msg.sender, _amount), "Token(_token).transfer(msg.sender, _amount)");
        }
        
        emit EmergencyWithdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
        success = true;
    }

    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function adminWithdraw(address _token, uint256 _amount, address _user, uint256 _nonce, uint8 _v, bytes32[2] _rs, uint256[2] _fee) public onlyAdmin returns (bool success) {

           
        
        
        bytes32 hash = keccak256(abi.encodePacked(this, _fee[1], _token, _amount, _user, _nonce));
        require(!hashed[hash], "!hashed[hash]");
        hashed[hash] = true;
        
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _rs[0], _rs[1]) == _user, "invalid withdraw signature");
        
        require(tokens[_token][_user] >= _amount, "not enough balance for withdrawal");
        
        tokens[_token][_user] = tokens[_token][_user].sub(_amount);
        
        uint256 fee;
        if (_fee[1] == 1) fee = toWei(_amount, _token).mul(_fee[0]) / 1 ether;
        if (_fee[1] == 1 && tokens[tokedoToken][_user] >= fee) {
            tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add(fee);
            tokens[tokedoToken][_user] = tokens[tokedoToken][_user].sub(fee);
        } else {
            if (_fee[0] > maxFeeWithdrawal) _fee[0] = maxFeeWithdrawal;
            
            fee = _fee[0].mul(_amount) / 1 ether;
            tokens[_token][feeAccount] = tokens[_token][feeAccount].add(fee);
            _amount = _amount.sub(fee);
        }
        
        if (_token == address(0)) {
            require(_user.send(_amount), "_user.send(_amount)");
        } else {
            require(Token(_token).transfer(_user, _amount), "Token(_token).transfer(_user, _amount)");
        }
        
        lastActiveTransaction[_user] = now;
        
        emit Withdraw(_token, _user, _amount, tokens[_token][_user]);
        success = true;
  }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }
    
    
     
    
    function adminTrade(uint256[] _values, address[] _addresses, uint8[] _v, bytes32[] _rs) public onlyAdmin returns (bool success) {
          
         
         
         
        
         
        if (_values[2] > maxFeeTrade) _values[2] = maxFeeTrade;     
        
         
        if (_values[5] > maxFeeTrade) _values[5] = maxFeeTrade;     
    
         
        
         
        require(tokens[_addresses[0]][_addresses[2]] >= _values[0],
                "tokens[tokenBuyAddress][takerAddress] >= amountSellTaker");
        
         
        
        bytes32[2] memory orderHash;
        uint256[8] memory amount;
         
        
         
        amount[2] = _values[0];
        
        for(uint256 i=0; i < (_values.length - 6) / 5; i++) {
            
             
            
             
            require(_values[i*5+9] >= invalidOrder[_addresses[i+3]],
                    "nonceMaker >= invalidOrder[makerAddress]" );
            
             
            orderHash[1] =  keccak256(abi.encodePacked(abi.encodePacked(this, _addresses[0], _values[i*5+6], _addresses[1], _values[i*5+7], _values[i*5+8], _values[i*5+9], _addresses[i+3]), _values[i*5+10]));
            
             
            orderHash[0] = keccak256(abi.encodePacked(orderHash[0], orderHash[1]));
            
             
            require(_addresses[i+3] == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash[1])), _v[i+1], _rs[i*2+2], _rs[i*2+3]),
                    'makerAddress    == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", makerHash  )), vMaker, rMaker   , sMaker   )');
            
            
             
            
             
            amount[1] = _values[i*5+6].sub(orderFills[orderHash[1]]); 

             
            if (amount[2] < amount[1]) {
                 
                amount[1] = amount[2]; 
            }
            
             
            amount[2] = amount[2].sub(amount[1]); 
            
             
            amount[0] = amount[0].add(amount[1]);
            
            
             
            
             
            require(tokens[_addresses[1]][_addresses[i+3]] >= (_values[i*5+7].mul(amount[1]).div(_values[i*5+6])),
                    "tokens[tokenSellAddress][makerAddress] >= (amountSellMaker.mul(appliedAmountSellTaker).div(amountBuyMaker))");
            
            
             
             
             
            
             
            amount[1] = toWei(amount[1], _addresses[0]);
            
             
            _values[i*5+7] = toWei(_values[i*5+7], _addresses[1]);
            
             
            _values[i*5+6] = toWei(_values[i*5+6], _addresses[0]);
            
             
            amount[3] = amount[1].mul(_values[5]).div(1e18);
             
            amount[4] = _values[i*5+7].mul(_values[2]).mul(amount[1]).div(_values[i*5+6]) / 1e18;
            
             
            if (_addresses[0] == address(0) || (baseCurrency[_addresses[0]] && !(_addresses[1] == address(0)))) {  
                 
                 
                 
                 
                
                 
                if (_values[i*5+10] == 1) amount[6] = amount[3].mul(1e18).div(_values[3]).mul(tokedoTokenFeeDiscount).div(1e18);
                
                 
                if (_values[4] == 1) {
                     
                    amount[5] = _values[i*5+6].mul(1e18).div(_values[i*5+7]);  
                     
                    amount[7] = amount[4].mul(amount[5]).div(_values[3]).mul(tokedoTokenFeeDiscount).div(1e18);
                }
                
                 
                amount[4] = fromWei(amount[4], _addresses[1]);
                
            } else {  
                 
                 
                 
                 

                 
                if(_values[4] == 1) amount[7] = amount[4].mul(1e18).div(_values[3]).mul(tokedoTokenFeeDiscount).div(1e18);
                
                 
                if (_values[i*5+10] == 1) {
                     
                    amount[5] = _values[i*5+7].mul(1e18).div(_values[i*5+6]);  
                
                     
                    amount[6] = amount[3].mul(amount[5]).div(_values[3]).mul(tokedoTokenFeeDiscount).div(1e18);
                }
                
                 
                amount[3] = fromWei(amount[3], _addresses[0]);
                
            }
            
             
            amount[1] = fromWei(amount[1], _addresses[0]);
            
             
            _values[i*5+7] = fromWei(_values[i*5+7], _addresses[1]);
            
             
            _values[i*5+6] = fromWei(_values[i*5+6], _addresses[0]);
            
            
             
            
             
            if (_values[4] == 1 && tokens[tokedoToken][_addresses[2]] >= amount[7] ) {
                
                 
                tokens[tokedoToken][_addresses[2]] = tokens[tokedoToken][_addresses[2]].sub(amount[7]);
                
                 
                tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add(amount[7]);
                
                 
                amount[4] = 0;
            } else {
                 
                tokens[_addresses[1]][feeAccount] = tokens[_addresses[1]][feeAccount].add(amount[4]);
            }
            
             
            if (_values[i*5+10] == 1 && tokens[tokedoToken][_addresses[i+3]] >= amount[6]) {
                
                 
                tokens[tokedoToken][_addresses[i+3]] = tokens[tokedoToken][_addresses[i+3]].sub(amount[6]);
                
                 
                tokens[tokedoToken][feeAccount] = tokens[tokedoToken][feeAccount].add(amount[6]);
                
                 
                amount[3] = 0;
            } else {
                 
                tokens[_addresses[0]][feeAccount] = tokens[_addresses[0]][feeAccount].add(amount[3]);
            }
            
        
             
            
         
        tokens[_addresses[0]][_addresses[2]] = tokens[_addresses[0]][_addresses[2]].sub(amount[1]);
            
             
            tokens[_addresses[0]][_addresses[i+3]] = tokens[_addresses[0]][_addresses[i+3]].add(amount[1].sub(amount[3]));
            
            
             
            tokens[_addresses[1]][_addresses[i+3]] = tokens[_addresses[1]][_addresses[i+3]].sub(_values[i*5+7].mul(amount[1]).div(_values[i*5+6]));
            
         
        tokens[_addresses[1]][_addresses[2]] = tokens[_addresses[1]][_addresses[2]].add(_values[i*5+7].mul(amount[1]).div(_values[i*5+6]).sub(amount[4]));
            
            
             
                        
             
            orderFills[orderHash[1]] = orderFills[orderHash[1]].add(amount[1]);
            
             
            lastActiveTransaction[_addresses[i+3]] = now; 
            
        }
        
        
         

         
        bytes32 tradeHash = keccak256(abi.encodePacked(orderHash[0], _values[0], _addresses[2], _values[1], _values[4])); 
        
         
        require(_addresses[2] == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash)), _v[0], _rs[0], _rs[1]), 
                'takerAddress  == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash)), vTaker, rTaker, sTaker)');
        
         
        require(!hashed[tradeHash], "!hashed[tradeHash] ");
        hashed[tradeHash] = true;
        
         
        require(amount[0] == _values[0], "totalBuyMakerAmount == amountSellTaker");
        
        
         
        
         
        lastActiveTransaction[_addresses[2]] = now; 
        
        success = true;
    }
    function toWei(uint256 _number, address _token) internal view returns (uint256) {
        if (_token == address(0)) return _number;
        return _number.mul(1e18).div(10**uint256(Token(_token).decimals()));
    }
    function fromWei(uint256 _number, address _token) internal view returns (uint256) {
        if (_token == address(0)) return _number;
        return _number.mul(10**uint256(Token(_token).decimals())).div(1e18);
    }
}