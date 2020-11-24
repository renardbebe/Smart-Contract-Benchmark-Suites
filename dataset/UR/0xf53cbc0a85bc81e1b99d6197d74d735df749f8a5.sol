 

pragma solidity ^0.4.17;

 
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract iEthealSale {
    bool public paused;
    uint256 public minContribution;
    uint256 public whitelistThreshold;
    mapping (address => uint256) public stakes;
    function setPromoBonus(address _investor, uint256 _value) public;
    function buyTokens(address _beneficiary) public payable;
    function depositEth(address _beneficiary, uint256 _time, bytes _whitelistSign) public payable;
    function depositOffchain(address _beneficiary, uint256 _amount, uint256 _time) public;
    function hasEnded() public constant returns (bool);
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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






 
contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);

     
     
     
     
     
    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}






 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

 
contract EthealWhitelist is Ownable {
    using ECRecovery for bytes32;

     
    address public signer;

     
    mapping(address => bool) public isWhitelisted;

    event WhitelistSet(address indexed _address, bool _state);

     
     
     
    function EthealWhitelist(address _signer) {
        require(_signer != address(0));

        signer = _signer;
    }

     
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));

        signer = _signer;
    }

     
     
     

     
    function setWhitelist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
        isWhitelisted[_addr] = _state;
        WhitelistSet(_addr, _state);
    }

     
    function setManyWhitelist(address[] _addr, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i], _state);
        }
    }

     
    function isOffchainWhitelisted(address _addr, bytes _sig) public view returns (bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n20",_addr);
        return hash.recover(_sig) == signer;
    }
}


 
contract EthealDeposit is Ownable, HasNoTokens {
    using SafeMath for uint256;

     
    struct Deposit {
        uint256 amount;          
        address beneficiary;     
        uint64 time;             
        bool cleared;            
    }
    uint256 public transactionCount;
    uint256 public pendingCount;
    mapping (uint256 => Deposit) public transactions;     
    mapping (address => uint256[]) public addressTransactions;   
    
     
    iEthealSale public sale;
    EthealWhitelist public whitelist;

    event LogDeposited(address indexed beneficiary, uint256 weiAmount, uint256 id);
    event LogRefunded(address indexed beneficiary, uint256 weiAmount, uint256 id);
    event LogForwarded(address indexed beneficiary, uint256 weiAmount, uint256 id);

     
     
     

     
     
     
    function EthealDeposit(address _sale, address _whitelist) {
        require(_sale != address(0));
        sale = iEthealSale(_sale);
        whitelist = EthealWhitelist(_whitelist);
    }

     
    function setSale(address _sale) public onlyOwner {
        sale = iEthealSale(_sale);
    }

     
    function setWhitelist(address _whitelist) public onlyOwner {
        whitelist = EthealWhitelist(_whitelist);
    }

     
    function extractTokens(address _token, address _claimer) public onlyOwner saleEnded {
        require(pendingCount == 0);

        super.extractTokens(_token, _claimer);
    }


     
     
     

    modifier whitelistSet() {
        require(address(whitelist) != address(0));
        _;
    }

    modifier saleNotEnded() {
        require(address(sale) != address(0) && !sale.hasEnded());
        _;
    }

    modifier saleNotPaused() {
        require(address(sale) != address(0) && !sale.paused());
        _;
    }

    modifier saleEnded() {
        require(address(sale) != address(0) && sale.hasEnded());
        _;
    }

     
    function() public payable {
        deposit(msg.sender, "");
    }

     
     
     
    function deposit(address _investor, bytes _whitelistSign) public payable whitelistSet saleNotEnded returns (uint256) {
        require(_investor != address(0));
        require(msg.value > 0);
        require(msg.value >= sale.minContribution());

        uint256 transactionId = addTransaction(_investor, msg.value);

         
        if (whitelist.isWhitelisted(_investor) 
            || whitelist.isOffchainWhitelisted(_investor, _whitelistSign) 
            || sale.whitelistThreshold() >= sale.stakes(_investor).add(msg.value)
        ) {
             
            if (!sale.paused()) {
                forwardTransactionInternal(transactionId, _whitelistSign);
            }
        }

        return transactionId;
    }

     
    function forwardTransaction(uint256 _id, bytes _whitelistSign) public whitelistSet saleNotEnded saleNotPaused {
        require(forwardTransactionInternal(_id, _whitelistSign));
    }

     
    function forwardManyTransaction(uint256[] _ids) public whitelistSet saleNotEnded saleNotPaused {
        uint256 _threshold = sale.whitelistThreshold();

        for (uint256 i=0; i<_ids.length; i++) {
             
            if ( whitelist.isWhitelisted(transactions[_ids[i]].beneficiary) 
                || _threshold >= sale.stakes(transactions[_ids[i]].beneficiary).add(transactions[_ids[i]].amount )
            ) {
                forwardTransactionInternal(_ids[i],"");
            }
        }
    }

     
    function forwardInvestorTransaction(address _investor, bytes _whitelistSign) public whitelistSet saleNotEnded saleNotPaused {
        bool _whitelisted = whitelist.isWhitelisted(_investor) || whitelist.isOffchainWhitelisted(_investor, _whitelistSign);
        uint256 _amount = sale.stakes(_investor);
        uint256 _threshold = sale.whitelistThreshold();

        for (uint256 i=0; i<addressTransactions[_investor].length; i++) {
            _amount = _amount.add(transactions[ addressTransactions[_investor][i] ].amount);
             
            if (_whitelisted || _threshold >= _amount) {
                forwardTransactionInternal(addressTransactions[_investor][i], _whitelistSign);
            }
        }
    }

     
    function refundTransaction(uint256 _id) public saleEnded {
        require(refundTransactionInternal(_id));
    }

     
    function refundManyTransaction(uint256[] _ids) public saleEnded {
        for (uint256 i=0; i<_ids.length; i++) {
            refundTransactionInternal(_ids[i]);
        }
    }

     
    function refundInvestor(address _investor) public saleEnded {
        for (uint256 i=0; i<addressTransactions[_investor].length; i++) {
            refundTransactionInternal(addressTransactions[_investor][i]);
        }
    }


     
     
     

     
    function addTransaction(address _investor, uint256 _amount) internal returns (uint256) {
        uint256 transactionId = transactionCount;

         
        transactions[transactionId] = Deposit({
            amount: _amount,
            beneficiary: _investor,
            time: uint64(now),
            cleared : false
        });

         
        addressTransactions[_investor].push(transactionId);

        transactionCount = transactionCount.add(1);
        pendingCount = pendingCount.add(1);
        LogDeposited(_investor, _amount, transactionId);

        return transactionId;
    }

     
     
    function forwardTransactionInternal(uint256 _id, bytes memory _whitelistSign) internal returns (bool) {
        require(_id < transactionCount);

         
        if (transactions[_id].cleared) {
            return false;
        }

         
        bytes memory _whitelistCall = bytesToArgument(_whitelistSign, 96);

         
        if (! sale.call.value(transactions[_id].amount)(bytes4(keccak256('depositEth(address,uint256,bytes)')), transactions[_id].beneficiary, uint256(transactions[_id].time), _whitelistCall) ) {
            return false;
        }
        transactions[_id].cleared = true;

        pendingCount = pendingCount.sub(1);
        LogForwarded(transactions[_id].beneficiary, transactions[_id].amount, _id);

        return true;
    }

     
    function bytesToArgument(bytes memory _sign, uint256 _position) internal pure returns (bytes memory c) {
        uint256 signLength = _sign.length;
        uint256 totalLength = signLength.add(64);
        uint256 loopMax = signLength.add(31).div(32);
        assembly {
            let m := mload(0x40)
            mstore(m, totalLength)           
            mstore(add(m,32), _position)     
            mstore(add(m,64), signLength)    
            for {  let i := 0 } lt(i, loopMax) { i := add(1, i) } { mstore(add(m, mul(32, add(3, i))), mload(add(_sign, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totalLength)))
            c := m
        }
    }

     
    function refundTransactionInternal(uint256 _id) internal returns (bool) {
        require(_id < transactionCount);

         
        if (transactions[_id].cleared) {
            return false;
        }

         
        transactions[_id].cleared = true;
        transactions[_id].beneficiary.transfer(transactions[_id].amount);

        pendingCount = pendingCount.sub(1);
        LogRefunded(transactions[_id].beneficiary, transactions[_id].amount, _id);

        return true;
    }


     
     
     

     
    function getTransactionIds(uint256 from, uint256 to, bool _cleared, bool _nonCleared) view external returns (uint256[] ids) {
        uint256 i = 0;
        uint256 results = 0;
        uint256[] memory _ids = new uint256[](transactionCount);

         
        for (i = 0; i < transactionCount; i++) {
            if (_cleared && transactions[i].cleared || _nonCleared && !transactions[i].cleared) {
                _ids[results] = i;
                results++;
            }
        }

        ids = new uint256[](results);
        for (i = from; i <= to && i < results; i++) {
            ids[i] = _ids[i];
        }

        return ids;
    }
}