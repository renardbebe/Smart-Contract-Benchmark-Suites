 

 
 
pragma solidity ^0.4.21;

contract CryptoDivert {
    using SafeMath for uint256;  
    
     
     
    address private admin;
    
     
     
     
    address private pendingAdmin; 
    
     
    address private constant NO_ADDRESS = address(0);
    
     
     
    mapping (bytes20 => address) private senders;
    
     
    mapping (bytes20 => uint256) private timers;
    
     
    mapping (bytes20 => uint16) private privacyDeviation;
    
     
    mapping (bytes20 => uint256) private balances;
    
     
    uint256 private userBalance;  
    
     
    uint256 private privacyFund;
    
     
    event ContractAdminTransferPending(address pendingAdmin, address currentAdmin);
    event NewContractAdmin(address newAdmin, address previousAdmin);
    event SafeGuardSuccess(bytes20 hash, uint256 value, uint256 comissions);
    event RetrieveSuccess(uint256 value);
    
    
     
     
    modifier isAddress(address _who) {
        require(_who != NO_ADDRESS);
        _;
    }
    
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size +4);  
        _;
    }
    
     
    modifier OnlyByAdmin() {
        require(msg.sender == admin);
        _;
    }
    
     
    modifier isNotAdmin(address _who) {
        require(_who != admin);
        _;
    }

     
    function CryptoDivert() public {
         
         
         
        admin = msg.sender;
    }
    
     
    function() public payable {
    }
    
     
     
    function ping() external view returns(string, uint256) {
        return ("CryptoDivert version 2018.04.05", now);
    }
    
    
     
    function showPendingAdmin() external view 
    OnlyByAdmin()
    returns(address) 
    {
        require(pendingAdmin != NO_ADDRESS);
        return pendingAdmin;
    }
    
     
    function whoIsAdmin() external view 
    returns(address) 
    {
        return admin;
    }
    
     
    function AuditBalances() external view returns(uint256, uint256) {
        assert(address(this).balance >= userBalance);
        uint256 pendingBalance = userBalance.add(privacyFund);
        uint256 commissions = address(this).balance.sub(pendingBalance);
        
        return(pendingBalance, commissions);
    }
    
     
    function AuditSafeGuard(bytes20 _originAddressHash) external view 
    returns(uint256 _safeGuarded, uint256 _timelock, uint16 _privacypercentage)
    {
         
        require(msg.sender == senders[_originAddressHash] || msg.sender == admin);
         
        _safeGuarded = balances[_originAddressHash];
        _timelock = timers[_originAddressHash];
        _privacypercentage = privacyDeviation[_originAddressHash];
        
        return (_safeGuarded, _timelock, _privacypercentage);
    }
    
    
     
     
    function SafeGuard(bytes20 _originAddressHash, uint256 _releaseTime, uint16 _privacyCommission) external payable
    onlyPayloadSize(3*32)
    returns(bool)
    {
         
         
        require(msg.value >= 1 finney); 
        
         
         
         
         
         
        require(senders[_originAddressHash] == NO_ADDRESS || balances[_originAddressHash] > 0);
       
         
         
         
         
        if(senders[_originAddressHash] == NO_ADDRESS) {
            
            senders[_originAddressHash] = msg.sender;
            
             
            if (_releaseTime > now) {
                timers[_originAddressHash] = _releaseTime;
            } else {
                timers[_originAddressHash] = now;
            }
            
             
            if (_privacyCommission > 0 && _privacyCommission <= 10000) {
                privacyDeviation[_originAddressHash] = _privacyCommission;
            }
        }    
        
         
        uint256 _commission = msg.value.div(125);  
        uint256 _balanceAfterCommission = msg.value.sub(_commission);
        balances[_originAddressHash] = balances[_originAddressHash].add(_balanceAfterCommission);
        
         
        userBalance = userBalance.add(_balanceAfterCommission);
        
         
         
         
        assert(address(this).balance >= userBalance); 
        
         
        emit SafeGuardSuccess(_originAddressHash, _balanceAfterCommission, _commission);
        
        return true;
    } 
    
      
    function Retrieve(string _password, address _originAddress) external 
    isAddress(_originAddress) 
    onlyPayloadSize(2*32)
    returns(bool)
    {
        
         
         
         
        bytes20 _addressHash = _getOriginAddressHash(_originAddress, _password); 
        bytes20 _senderHash = _getOriginAddressHash(msg.sender, _password); 
        bytes20 _transactionHash;
        uint256 _randomPercentage;  
        uint256 _month = 30 * 24 * 60 * 60;
        
         
         
        if (_originAddress == senders[_addressHash]) {  
            
             
            _transactionHash = _addressHash;
            
        } 
        else if (msg.sender == senders[_addressHash] && timers[_addressHash].add(_month) < now ) {  
            
             
            _transactionHash = _addressHash;
            
        }
        else {  
            
             
            _transactionHash = _senderHash;
        }
        
         
         
         
        if (balances[_transactionHash] == 0) {
            emit RetrieveSuccess(0);
            return false;    
        }
        
         
         
         
         
        if (timers[_transactionHash] > now ) {
            emit RetrieveSuccess(0);
            return false;
        }
        
         
        uint256 _balance = balances[_transactionHash];
        balances[_transactionHash] = 0;
        
         
         
         
         
         
        if (privacyDeviation[_transactionHash] > 0) {
             _randomPercentage = _randomize(now, privacyDeviation[_transactionHash]);
        }
        
        if(_randomPercentage > 0) {
             
            uint256 _privacyCommission = _balance.div(10000).mul(_randomPercentage);
            
             
            if (userBalance.add(privacyFund) > address(this).balance) {
                privacyFund = 0;
            }
            
             
            if (_privacyCommission <= privacyFund) {
                 
                 privacyFund = privacyFund.sub(_privacyCommission);
                 userBalance = userBalance.add(_privacyCommission);
                _balance = _balance.add(_privacyCommission);
               
            } else {
                 
                _balance = _balance.sub(_privacyCommission);
                userBalance = userBalance.sub(_privacyCommission);
                privacyFund = privacyFund.add(_privacyCommission);
            }
        }
        
         
        userBalance = userBalance.sub(_balance);
        
         
        msg.sender.transfer(_balance);
        
         
        assert(address(this).balance >= userBalance);
        
        emit RetrieveSuccess(_balance);
        
        return true;
    }
    
     
    function RetrieveCommissions() external OnlyByAdmin() {
         
         
        uint256 pendingBalance = userBalance.add(privacyFund);
        uint256 commissions = address(this).balance.sub(pendingBalance);
        
         
        msg.sender.transfer(commissions);
        
         
        assert(address(this).balance >= userBalance);
    } 
    
     
    function setAdmin(address _newAdmin) external 
    OnlyByAdmin() 
    isAddress(_newAdmin)
    isNotAdmin(_newAdmin)
    onlyPayloadSize(32)
    {
        pendingAdmin = _newAdmin;
        emit ContractAdminTransferPending(pendingAdmin, admin);
    }
    
      
    function confirmAdmin() external
    {
        require(msg.sender==pendingAdmin);
        address _previousAdmin = admin;
        admin = pendingAdmin;
        pendingAdmin = NO_ADDRESS;
        
        emit NewContractAdmin(admin, _previousAdmin);
    }
    
    
     
     
    function _randomize(uint256 _seed, uint256 _max) private view returns(uint256 _return) {
        _return = uint256(keccak256(_seed, block.blockhash(block.number -1), block.difficulty, block.coinbase));
        return _return % _max;
    }
    
    function _getOriginAddressHash(address _address, string _password) private pure returns(bytes20) {
        string memory _addressString = toAsciiString(_address);
        return ripemd160(_password,"0x",_addressString);
    }
    
    function toAsciiString(address x) private pure returns (string) {
    bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(byte b) private pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}