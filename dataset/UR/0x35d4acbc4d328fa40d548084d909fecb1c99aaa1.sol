 

pragma solidity ^0.4.23;

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Autonomy is Ownable {
    address public congress;
    bool init = false;

    modifier onlyCongress() {
        require(msg.sender == congress);
        _;
    }

     
    function initialCongress(address _congress) onlyOwner public {
        require(!init);
        require(_congress != address(0));
        congress = _congress;
        init = true;
    }

     
    function changeCongress(address _congress) onlyCongress public {
        require(_congress != address(0));
        congress = _congress;
    }
}

contract withdrawable is Ownable {
    event ReceiveEther(address _from, uint256 _value);
    event WithdrawEther(address _to, uint256 _value);
    event WithdrawToken(address _token, address _to, uint256 _value);

     
    function () payable public {
        emit ReceiveEther(msg.sender, msg.value);
    }

     
    function withdraw(address _to, uint _amount) public onlyOwner returns (bool) {
        require(_to != address(0));
        _to.transfer(_amount);
        emit WithdrawEther(_to, _amount);

        return true;
    }

     
    function withdrawToken(address _token, address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_token != address(0));

        ERC20 tk = ERC20(_token);
        tk.transfer(_to, _value);
        emit WithdrawToken(_token, _to, _value);

        return true;
    }

     
     
     
     
        
     
     
        
     
     
}

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

         
        ownedContract.claimOwnership();

        return true;
    }

     
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

     
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
}

contract DepositWithdraw is Claimable, withdrawable {
    using SafeMath for uint256;

     
    struct TransferRecord {
        uint256 timeStamp;
        address account;
        uint256 value;
    }
    
     
    struct accumulatedRecord {
        uint256 mul;
        uint256 count;
        uint256 value;
    }

    TransferRecord[] deposRecs;  
    TransferRecord[] withdrRecs;  

    accumulatedRecord dayWithdrawRec;  
    accumulatedRecord monthWithdrawRec;  

    address wallet;  

    event ReceiveDeposit(address _from, uint256 _value, address _token, bytes _extraData);
    
     
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

     
    function setWithdrawWallet(address _wallet) onlyOwner public returns (bool) {
        require(_wallet != address(0));
        wallet = _wallet;

        return true;
    }

     
    function bytesToBytes32(bytes _data) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(_data, 32))
        }
    }

     
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) onlyOwner public {
        require(_token != address(0));
        require(_from != address(0));
        
        ERC20 tk = ERC20(_token);
        require(tk.transferFrom(_from, this, _value));
        bytes32 timestamp = bytesToBytes32(_extraData);
        deposRecs.push(TransferRecord(uint256(timestamp), _from, _value));
        emit ReceiveDeposit(_from, _value, _token, _extraData);
    }

     
    function withdrawToken(address _token, address _params, uint256 _time, address _to, uint256 _value, uint256 _fee, address _tokenReturn) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_token != address(0));
        require(_value > _fee);
         

        DRCWalletMgrParams params = DRCWalletMgrParams(_params);
        require(_value <= params.singleWithdrawMax());
        require(_value >= params.singleWithdrawMin());

        uint256 daysCount = _time.div(86400);  
        if (daysCount <= dayWithdrawRec.mul) {
            dayWithdrawRec.count = dayWithdrawRec.count.add(1);
            dayWithdrawRec.value = dayWithdrawRec.value.add(_value);
            require(dayWithdrawRec.count <= params.dayWithdrawCount());
            require(dayWithdrawRec.value <= params.dayWithdraw());
        } else {
            dayWithdrawRec.mul = daysCount;
            dayWithdrawRec.count = 1;
            dayWithdrawRec.value = _value;
        }
        
        uint256 monthsCount = _time.div(86400 * 30);
        if (monthsCount <= monthWithdrawRec.mul) {
            monthWithdrawRec.count = monthWithdrawRec.count.add(1);
            monthWithdrawRec.value = monthWithdrawRec.value.add(_value);
            require(monthWithdrawRec.value <= params.monthWithdraw());
        } else {            
            monthWithdrawRec.mul = monthsCount;
            monthWithdrawRec.count = 1;
            monthWithdrawRec.value = _value;
        }

        ERC20 tk = ERC20(_token);
        uint256 realAmount = _value.sub(_fee);
        require(tk.transfer(_to, realAmount));
        if (_tokenReturn != address(0) && _fee > 0) {
            require(tk.transfer(_tokenReturn, _fee));
        }

        withdrRecs.push(TransferRecord(_time, _to, realAmount));
        emit WithdrawToken(_token, _to, realAmount);

        return true;
    }

     
    function withdrawTokenToDefault(address _token, address _params, uint256 _time, uint256 _value, uint256 _fee, address _tokenReturn) public onlyOwner returns (bool) {
        return withdrawToken(_token, _params, _time, wallet, _value, _fee, _tokenReturn);
    }

     
    function getDepositNum() public view returns (uint256) {
        return deposRecs.length;
    }

     
    function getOneDepositRec(uint256 _ind) public view returns (uint256, address, uint256) {
        require(_ind < deposRecs.length);

        return (deposRecs[_ind].timeStamp, deposRecs[_ind].account, deposRecs[_ind].value);
    }

     
    function getWithdrawNum() public view returns (uint256) {
        return withdrRecs.length;
    }
    
     
    function getOneWithdrawRec(uint256 _ind) public view returns (uint256, address, uint256) {
        require(_ind < withdrRecs.length);

        return (withdrRecs[_ind].timeStamp, withdrRecs[_ind].account, withdrRecs[_ind].value);
    }
}

contract DRCWalletManager is OwnerContract, withdrawable, Destructible, TokenDestructible {
    using SafeMath for uint256;
    
     
    struct WithdrawWallet {
        bytes32 name;
        address walletAddr;
    }

     
    struct DepositRepository {
         
        uint256 frozen;
        WithdrawWallet[] withdrawWallets;
         
    }

    mapping (address => DepositRepository) depositRepos;
    mapping (address => address) walletDeposits;
    mapping (address => bool) public frozenDeposits;

    ERC20 public tk;  
    DRCWalletMgrParams params;  
    
    event CreateDepositAddress(address indexed _wallet, address _deposit);
    event FrozenTokens(address indexed _deposit, uint256 _value);
    event ChangeDefaultWallet(address indexed _oldWallet, address _newWallet);

     
    function bindToken(address _token, address _walletParams) onlyOwner public returns (bool) {
        require(_token != address(0));
        require(_walletParams != address(0));

        tk = ERC20(_token);
        params = DRCWalletMgrParams(_walletParams);
        return true;
    }
    
     
    function createDepositContract(address _wallet) onlyOwner public returns (address) {
        require(_wallet != address(0));

        DepositWithdraw deposWithdr = new DepositWithdraw(_wallet);  
        address _deposit = address(deposWithdr);
        walletDeposits[_wallet] = _deposit;
        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        withdrawWalletList.push(WithdrawWallet("default wallet", _wallet));
         
        depositRepos[_deposit].frozen = 0;

        emit CreateDepositAddress(_wallet, address(deposWithdr));
        return deposWithdr;
    }
    
     
    function getDepositAddress(address _wallet) onlyOwner public view returns (address) {
        require(_wallet != address(0));
        address deposit = walletDeposits[_wallet];

        return deposit;
    }
    
     
    function getDepositInfo(address _deposit) onlyOwner public view returns (uint256, uint256) {
        require(_deposit != address(0));
        uint256 _balance = tk.balanceOf(_deposit);
        uint256 frozenAmount = depositRepos[_deposit].frozen;
         

        return (_balance, frozenAmount);
    }
    
     
    function getDepositWithdrawCount(address _deposit) onlyOwner public view returns (uint) {
        require(_deposit != address(0));

        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        uint len = withdrawWalletList.length;

        return len;
    }
    
     
    function getDepositWithdrawList(address _deposit, uint[] _indices) onlyOwner public view returns (bytes32[], address[]) {
        require(_indices.length != 0);

        bytes32[] memory names = new bytes32[](_indices.length);
        address[] memory wallets = new address[](_indices.length);
        
        for (uint i = 0; i < _indices.length; i = i.add(1)) {
            WithdrawWallet storage wallet = depositRepos[_deposit].withdrawWallets[_indices[i]];
            names[i] = wallet.name;
            wallets[i] = wallet.walletAddr;
        }
        
        return (names, wallets);
    }
    
     
    function changeDefaultWithdraw(address _oldWallet, address _newWallet) onlyOwner public returns (bool) {
        require(_newWallet != address(0));
        
        address deposit = walletDeposits[_oldWallet];
        DepositWithdraw deposWithdr = DepositWithdraw(deposit);
        require(deposWithdr.setWithdrawWallet(_newWallet));

        WithdrawWallet[] storage withdrawWalletList = depositRepos[deposit].withdrawWallets;
        withdrawWalletList[0].walletAddr = _newWallet;
        emit ChangeDefaultWallet(_oldWallet, _newWallet);

        return true;
    }
    
     
    function freezeTokens(address _deposit, uint256 _value) onlyOwner public returns (bool) {
        require(_deposit != address(0));
        
        frozenDeposits[_deposit] = true;
        depositRepos[_deposit].frozen = _value;

        emit FrozenTokens(_deposit, _value);
        return true;
    }
    
     
    function withdrawWithFee(address _deposit, uint256 _time, uint256 _value) onlyOwner public returns (bool) {
        require(_deposit != address(0));

        uint256 _balance = tk.balanceOf(_deposit);
        require(_value <= _balance);

         
        uint256 frozenAmount = depositRepos[_deposit].frozen;
        require(_value <= _balance.sub(frozenAmount));

        DepositWithdraw deposWithdr = DepositWithdraw(_deposit);
        return (deposWithdr.withdrawTokenToDefault(address(tk), address(params), _time, _value, params.chargeFee(), params.chargeFeePool()));
    }
    
     
    function checkWithdrawAddress(address _deposit, bytes32 _name, address _to) public view returns (bool, bool) {
        uint len = depositRepos[_deposit].withdrawWallets.length;
        for (uint i = 0; i < len; i = i.add(1)) {
            WithdrawWallet storage wallet = depositRepos[_deposit].withdrawWallets[i];
            if (_name == wallet.name) {
                return(true, (_to == wallet.walletAddr));
            }
        }

        return (false, true);
    }

     
    function withdrawWithFee(address _deposit, 
                             uint256 _time, 
                             bytes32 _name, 
                             address _to, 
                             uint256 _value, 
                             bool _check) onlyOwner public returns (bool) {
        require(_deposit != address(0));
        require(_to != address(0));

        uint256 _balance = tk.balanceOf(_deposit);
        if (_check) {
            require(_value <= _balance);
        }

        uint256 available = _balance.sub(depositRepos[_deposit].frozen);
        if (_check) {
            require(_value <= available);
        }

        bool exist;
        bool correct;
        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        (exist, correct) = checkWithdrawAddress(_deposit, _name, _to);
        if(!exist) {
            withdrawWalletList.push(WithdrawWallet(_name, _to));
        } else if(!correct) {
            return false;
        }

        if (!_check && _value > available) {
            tk.transfer(_deposit, _value.sub(available));
            _value = _value.sub(available);
        }

        DepositWithdraw deposWithdr = DepositWithdraw(_deposit);
        return (deposWithdr.withdrawToken(address(tk), address(params), _time, _to, _value, params.chargeFee(), params.chargeFeePool()));        
    }

}

contract DRCWalletMgrParams is Claimable, Autonomy, Destructible {
    uint256 public singleWithdrawMin;  
    uint256 public singleWithdrawMax;  
    uint256 public dayWithdraw;  
    uint256 public monthWithdraw;  
    uint256 public dayWithdrawCount;  

    uint256 public chargeFee;  
    address public chargeFeePool;  


    function initialSingleWithdrawMax(uint256 _value) onlyOwner public {
        require(!init);

        singleWithdrawMax = _value;
    }

    function initialSingleWithdrawMin(uint256 _value) onlyOwner public {
        require(!init);

        singleWithdrawMin = _value;
    }

    function initialDayWithdraw(uint256 _value) onlyOwner public {
        require(!init);

        dayWithdraw = _value;
    }

    function initialDayWithdrawCount(uint256 _count) onlyOwner public {
        require(!init);

        dayWithdrawCount = _count;
    }

    function initialMonthWithdraw(uint256 _value) onlyOwner public {
        require(!init);

        monthWithdraw = _value;
    }

    function initialChargeFee(uint256 _value) onlyOwner public {
        require(!init);

        chargeFee = _value;
    }

    function initialChargeFeePool(address _pool) onlyOwner public {
        require(!init);

        chargeFeePool = _pool;
    }    

    function setSingleWithdrawMax(uint256 _value) onlyCongress public {
        singleWithdrawMax = _value;
    }   

    function setSingleWithdrawMin(uint256 _value) onlyCongress public {
        singleWithdrawMin = _value;
    }

    function setDayWithdraw(uint256 _value) onlyCongress public {
        dayWithdraw = _value;
    }

    function setDayWithdrawCount(uint256 _count) onlyCongress public {
        dayWithdrawCount = _count;
    }

    function setMonthWithdraw(uint256 _value) onlyCongress public {
        monthWithdraw = _value;
    }

    function setChargeFee(uint256 _value) onlyCongress public {
        chargeFee = _value;
    }

    function setChargeFeePool(address _pool) onlyOwner public {
        chargeFeePool = _pool;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}