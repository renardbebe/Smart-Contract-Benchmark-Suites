 

pragma solidity 0.4.18;

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



 
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  
  function mod256(uint256 a, uint256 b) internal pure returns (uint256) {
	uint256 c = a % b;
	return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



 
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() public {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

   
  function burn(uint _value) onlyOwner public {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}

 
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      revert();
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      revert();
    }
    _;
  }
   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }
   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }
}

 
contract TeuBookingDeposit is Ownable, Pausable {
	event eAdjustClientAccountBalance(bytes32 indexed _PartnerID, bytes32 _ClientId, bytes32 _adjustedBy, string _CrDr, uint256 _tokenAmount, string CrDrR, uint256 _tokenRAmount);
	event eAllocateRestrictedTokenTo(bytes32 indexed _PartnerID, bytes32 indexed _clientId, bytes32 _allocatedBy, uint256 _tokenAmount);
	event eAllocateRestrictedTokenToPartner(bytes32 indexed _PartnerID, bytes32 _allocatedBy, uint256 _tokenAmount);
	event eCancelTransactionEvent(bytes32 indexed _PartnerID, string _TxNum, bytes32 indexed _fromClientId, uint256 _tokenAmount, uint256 _rAmount, uint256 _grandTotal);
	event eConfirmReturnToken(bytes32 indexed _PartnerID, string _TxNum, bytes32 indexed _fromClientId, uint256 _tokenAmount, uint256 _rAmount, uint256 _grandTotal);
    event eConfirmTokenTransferToBooking(bytes32 indexed _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _amount1, uint256 _rAmount1, uint256 _amount2, uint256 _rAmount2);
    event eKillTransactionEvent(bytes32 _PartnerID, bytes32 _killedBy, string TxHash, string _TxNum);
	event ePartnerAllocateRestrictedTokenTo(bytes32 indexed _PartnerID, bytes32 indexed _clientId, uint256 _tokenAmount);
	event eReceiveTokenByClientAccount(bytes32 indexed _clientId, uint256 _tokenAmount, address _transferFrom);
	event eSetWalletToClientAccount(bytes32 _clientId, address _wallet, bytes32 _setBy);
	event eTransactionFeeForBooking(bytes32 indexed _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _amount1, uint256 _rAmount1, uint256 _amount2, uint256 _rAmount2);
	event eWithdrawTokenToClientAccount(bytes32 indexed _clientId, bytes32 _withdrawnBy, uint256 _tokenAmount, address _transferTo);
	event eWithdrawUnallocatedRestrictedToken(uint256 _tokenAmount, bytes32 _withdrawnBy);
	
	
	
    using SafeMath for uint256;
	
	
    TeuToken    private token;
	 
    function drain() onlyOwner public {
        if (!owner.send(this.balance)) revert();
    }
	
	function () payable public {
		if (msg.value!=0) revert();
	}
	
	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
		bytes memory tempEmptyStringTest = bytes(source);
		if (tempEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly {
			result := mload(add(source, 32))
		}
	}
	
	function killTransaction(bytes32 _PartnerID, bytes32 _killedBy, string _txHash, string _txNum) onlyOwner stopInEmergency public {
		eKillTransactionEvent(_PartnerID, _killedBy, _txHash, _txNum);
	}
	
		
	function cancelTransaction(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _grandTotal) onlyOwner stopInEmergency public {
        eCancelTransactionEvent(_PartnerID, _TxNum, _fromClientId1, _tokenAmount1, _rAmount1, _grandTotal);
		eCancelTransactionEvent(_PartnerID, _TxNum, _toClientId2, _tokenAmount2, _rAmount2, _grandTotal);
	}
	
	
	function AdjustClientAccountBalance(bytes32 _PartnerID, bytes32 _ClientId, bytes32 _allocatedBy, string _CrDr, uint256 _tokenAmount, string CrDrR, uint256 _RtokenAmount) onlyOwner stopInEmergency public {
		eAdjustClientAccountBalance(_PartnerID, _ClientId, _allocatedBy, _CrDr, _tokenAmount, CrDrR, _RtokenAmount);
	}
	
	function setWalletToClientAccount(bytes32 _clientId, address _wallet, bytes32 _setBy) onlyOwner public {
        eSetWalletToClientAccount(_clientId, _wallet, _setBy);
    }
	
    function receiveTokenByClientAccount(string _clientId, uint256 _tokenAmount, address _transferFrom) stopInEmergency public {
        require(_tokenAmount > 0);
        bytes32 _clientId32 = stringToBytes32(_clientId);
		token.transferFrom(_transferFrom, this, _tokenAmount);   
		eReceiveTokenByClientAccount(_clientId32, _tokenAmount, _transferFrom);
    }
	
	function withdrawTokenToClientAccount(bytes32 _clientId, bytes32 _withdrawnBy, address _transferTo, uint256 _tokenAmount) onlyOwner stopInEmergency public {
        require(_tokenAmount > 0);

		token.transfer(_transferTo, _tokenAmount);      

		eWithdrawTokenToClientAccount(_clientId, _withdrawnBy, _tokenAmount, _transferTo);
    }
	

	
     
    function allocateRestrictedTokenTo(bytes32 _PartnerID, bytes32 _clientId, bytes32 _allocatedBy, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		eAllocateRestrictedTokenTo(_PartnerID, _clientId, _allocatedBy, _tokenAmount);
    }
    
    function withdrawUnallocatedRestrictedToken(uint256 _tokenAmount, bytes32 _withdrawnBy) onlyOwner stopInEmergency public {
         
        token.transfer(msg.sender, _tokenAmount);
		eWithdrawUnallocatedRestrictedToken(_tokenAmount, _withdrawnBy);
    } 

 
    function allocateRestrictedTokenToPartner(bytes32 _PartnerID, bytes32 _allocatedBy, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		eAllocateRestrictedTokenToPartner(_PartnerID, _allocatedBy, _tokenAmount);
    }
	
    function partnerAllocateRestrictedTokenTo(bytes32 _PartnerID, bytes32 _clientId, uint256 _tokenAmount) onlyOwner stopInEmergency public {
		ePartnerAllocateRestrictedTokenTo(_PartnerID, _clientId, _tokenAmount);
    }
	
 
	function confirmTokenTransferToBooking(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _txTokenAmount1, uint256 _txRAmount1, uint256 _txTokenAmount2, uint256 _txRAmount2) onlyOwner stopInEmergency public {		
		eConfirmTokenTransferToBooking(_PartnerID, _TxNum, _fromClientId1, _toClientId2, _tokenAmount1, _rAmount1, _tokenAmount2, _rAmount2);
		eTransactionFeeForBooking(_PartnerID, _TxNum, _fromClientId1, _toClientId2, _txTokenAmount1, _txRAmount1, _txTokenAmount2, _txRAmount2);
	}

 
 
	function confirmReturnToken(bytes32 _PartnerID, string _TxNum, bytes32 _fromClientId1, bytes32 _toClientId2, uint256 _tokenAmount1, uint256 _rAmount1, uint256 _tokenAmount2, uint256 _rAmount2, uint256 _grandTotal) onlyOwner stopInEmergency public {
        eConfirmReturnToken(_PartnerID, _TxNum, _fromClientId1, _tokenAmount1, _rAmount1, _grandTotal);
		eConfirmReturnToken(_PartnerID, _TxNum, _toClientId2, _tokenAmount2, _rAmount2, _grandTotal);
	}


 
    function getToken() constant public onlyOwner returns (address) {
        return token;
    }
	
    function setToken(address _token) public onlyOwner stopInEmergency {
        require(token == address(0));
        token = TeuToken(_token);
    }

}