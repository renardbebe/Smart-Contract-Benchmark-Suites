 

pragma solidity ^0.4.24;

interface IDRCWalletMgrParams {
    function singleWithdrawMin() external returns (uint256);  
    function singleWithdrawMax() external returns (uint256);  
    function dayWithdraw() external returns (uint256);  
    function monthWithdraw() external returns (uint256);  
    function dayWithdrawCount() external returns (uint256);  

    function chargeFee() external returns (uint256);  
    function chargeFeePool() external returns (address);  
}

interface IDRCWalletStorage {
     
    function walletDeposits(address _wallet) external view returns (address);

     
    function frozenDeposits(address _deposit) external view returns (bool);

     
    function wallet(address _deposit, uint256 _ind) external view returns (address);

     
    function walletName(address _deposit, uint256 _ind) external view returns (bytes32);

     
    function walletsNumber(address _deposit) external view returns (uint256);

     
    function frozenAmount(address _deposit) external view returns (uint256);

     
    function balanceOf(address _deposit) external view returns (uint256);

     
    function depositAddressByIndex(uint256 _ind) external view returns (address);

     
    function size() external view returns (uint256);

     
    function isExisted(address _deposit) external view returns (bool);

     
    function addDeposit(address _wallet, address _depositAddr) external returns (bool);

     
    function changeDefaultWallet(address _oldWallet, address _newWallet) external returns (bool);

     
    function freezeTokens(address _deposit, bool _freeze, uint256 _value) external returns (bool);

     
    function increaseBalance(address _deposit, uint256 _value) external returns (bool);

     
    function decreaseBalance(address _deposit, uint256 _value) external returns (bool);

     
    function addWithdraw(address _deposit, bytes32 _name, address _withdraw) external returns (bool);

     
    function changeWalletName(address _deposit, bytes32 _newName, address _wallet) external returns (bool);

     
    function removeDeposit(address _depositAddr) external returns (bool);

     
    function withdrawToken(address _token, address _to, uint256 _value) external returns (bool);
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

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Withdrawable is Ownable {
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

contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] _tokens) public onlyOwner {

     
    for (uint256 i = 0; i < _tokens.length; i++) {
      ERC20Basic token = ERC20Basic(_tokens[i]);
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DepositWithdraw is Claimable, Withdrawable, TokenDestructible {
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

     
     
     

     
     

     
    function recordWithdraw(uint256 _time, address _to, uint256 _value) onlyOwner public {
        withdrRecs.push(TransferRecord(_time, _to, _value));
    }

     
    function checkWithdrawAmount(address _params, uint256 _value, uint256 _time) public returns (bool) {
        IDRCWalletMgrParams params = IDRCWalletMgrParams(_params);
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

        return true;
    }

     
    function withdrawToken(address _token, address _params, uint256 _time, address _to, uint256 _value, uint256 _fee, address _tokenReturn) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_token != address(0));
        require(_value > _fee);
         

        require(checkWithdrawAmount(_params, _value, _time));

        ERC20 tk = ERC20(_token);
        uint256 realAmount = _value.sub(_fee);
        require(tk.transfer(_to, realAmount));
        if (_tokenReturn != address(0) && _fee > 0) {
            require(tk.transfer(_tokenReturn, _fee));
        }

        recordWithdraw(_time, _to, realAmount);
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

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

   
  function setLimits(uint256 _start, uint256 _end) public onlyOwner {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

   
  function claimOwnership() public onlyPendingOwner {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
  }

}

contract OwnerContract is DelayedClaimable {
    Claimable public ownedContract;
    address public pendingOwnedOwner;
     

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
         

         
        if (ownedContract.owner() != address(this)) {
            ownedContract.claimOwnership();
        }

        return true;
    }

     
     
     
     
     
     

     
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        require(ownedContract != address(0));

        if (ownedContract.owner() != pendingOwnedOwner) {
            ownedContract.transferOwnership(_nextOwner);
            pendingOwnedOwner = _nextOwner;
             
             
        } else {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
        }
    }

     
    function ownedOwnershipTransferred() onlyOwner public returns (bool) {
        require(ownedContract != address(0));
        if (ownedContract.owner() == pendingOwnedOwner) {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
            return true;
        } else {
            return false;
        }
    }
}

contract DRCWalletManager is OwnerContract, Withdrawable, TokenDestructible {
    using SafeMath for uint256;

     
     
     
     
     

     
     
     
     
     
     
     

     
     
     

    ERC20 public tk;  
    IDRCWalletMgrParams public params;  
    IDRCWalletStorage public walletStorage;  

    event CreateDepositAddress(address indexed _wallet, address _deposit);
    event FrozenTokens(address indexed _deposit, bool _freeze, uint256 _value);
    event ChangeDefaultWallet(address indexed _oldWallet, address _newWallet);

     
    function initialize(address _token, address _walletParams, address _walletStorage) onlyOwner public returns (bool) {
        require(_token != address(0));
        require(_walletParams != address(0));

        tk = ERC20(_token);
        params = IDRCWalletMgrParams(_walletParams);
        walletStorage = IDRCWalletStorage(_walletStorage);

        return true;
    }

     
    function createDepositContract(address _wallet) onlyOwner public returns (address) {
        require(_wallet != address(0));

        DepositWithdraw deposWithdr = new DepositWithdraw(_wallet);  
        address _deposit = address(deposWithdr);
         
         
         
         
         

        walletStorage.addDeposit(_wallet, _deposit);

         

        emit CreateDepositAddress(_wallet, _deposit);
        return _deposit;
    }

     
    function doDeposit(address _deposit, bool _increase, uint256 _value) onlyOwner public returns (bool) {
        return (_increase
                ? walletStorage.increaseBalance(_deposit, _value)
                : walletStorage.decreaseBalance(_deposit, _value));
    }

     
    function getDepositAddress(address _wallet) onlyOwner public view returns (address) {
        require(_wallet != address(0));
         

         
        return walletStorage.walletDeposits(_wallet);
    }

     
    function getDepositInfo(address _deposit) onlyOwner public view returns (uint256, uint256) {
        require(_deposit != address(0));
        uint256 _balance = walletStorage.balanceOf(_deposit);
         
        uint256 frozenAmount = walletStorage.frozenAmount(_deposit);
         

        return (_balance, frozenAmount);
    }

     
    function getDepositWithdrawCount(address _deposit) onlyOwner public view returns (uint) {
        require(_deposit != address(0));

         
         
        uint len = walletStorage.walletsNumber(_deposit);

        return len;
    }

     
    function getDepositWithdrawList(address _deposit, uint[] _indices) onlyOwner public view returns (bytes32[], address[]) {
        require(_indices.length != 0);

        bytes32[] memory names = new bytes32[](_indices.length);
        address[] memory wallets = new address[](_indices.length);

        for (uint i = 0; i < _indices.length; i = i.add(1)) {
             
             
             
            names[i] = walletStorage.walletName(_deposit, i);
            wallets[i] = walletStorage.wallet(_deposit, i);
        }

        return (names, wallets);
    }

     
    function changeDefaultWithdraw(address _oldWallet, address _newWallet) onlyOwner public returns (bool) {
        require(_oldWallet != address(0));
        require(_newWallet != address(0));

        address deposit = walletStorage.walletDeposits(_oldWallet);
        DepositWithdraw deposWithdr = DepositWithdraw(deposit);
        require(deposWithdr.setWithdrawWallet(_newWallet));

         
         
        bool res = walletStorage.changeDefaultWallet(_oldWallet, _newWallet);
        emit ChangeDefaultWallet(_oldWallet, _newWallet);

        return res;
    }

     
    function freezeTokens(address _deposit, bool _freeze, uint256 _value) onlyOwner public returns (bool) {
         

         
         
         
         
         
         
         

        bool res = walletStorage.freezeTokens(_deposit, _freeze, _value);

        emit FrozenTokens(_deposit, _freeze, _value);
        return res;
    }

     
    function withdrawWithFee(address _deposit, uint256 _time, uint256 _value, bool _check) onlyOwner public returns (bool) {
         
         
        bytes32 defaultWalletName = walletStorage.walletName(_deposit, 0);
        address defaultWallet = walletStorage.wallet(_deposit, 0);
        return withdrawWithFee(_deposit, _time, defaultWalletName, defaultWallet, _value, _check);
    }

     
    function checkWithdrawAddress(address _deposit, bytes32 _name, address _to) public view returns (bool, bool) {
         
        uint len = walletStorage.walletsNumber(_deposit);
        for (uint i = 0; i < len; i = i.add(1)) {
             
             
             
             
             
             
             
            bytes32 walletName = walletStorage.walletName(_deposit, i);
            address walletAddr = walletStorage.wallet(_deposit, i);
            if (_name == walletName) {
                return(true, (_to == walletAddr));
            }
            if (_to == walletAddr) {
                return(false, true);
            }
        }

        return (false, false);
    }

     
    function withdrawFromThis(DepositWithdraw _deposWithdr, uint256 _time, address _to, uint256 _value) private returns (bool) {
        uint256 fee = params.chargeFee();
        uint256 realAmount = _value.sub(fee);
        address tokenReturn = params.chargeFeePool();
        if (tokenReturn != address(0) && fee > 0) {
             
            require(walletStorage.withdrawToken(tk, tokenReturn, fee));
        }

         
        require(walletStorage.withdrawToken(tk, _to, realAmount));
        _deposWithdr.recordWithdraw(_time, _to, realAmount);

        return true;
    }

     
    function withdrawWithFee(address _deposit,
                             uint256 _time,
                             bytes32 _name,
                             address _to,
                             uint256 _value,
                             bool _check) onlyOwner public returns (bool) {
        require(_deposit != address(0));
        require(_to != address(0));

        uint256 totalBalance = walletStorage.balanceOf(_deposit);
        uint256 frozen = walletStorage.frozenAmount(_deposit);
         
         
        if (_check) {
            require(_value <= totalBalance.sub(frozen));
        }

        uint256 _balance = tk.balanceOf(_deposit);

        bool exist;
        bool correct;
         
        (exist, correct) = checkWithdrawAddress(_deposit, _name, _to);
        if(!exist) {
             
            if (!correct) {
                walletStorage.addWithdraw(_deposit, _name, _to);
            } else {
                walletStorage.changeWalletName(_deposit, _name, _to);
            }
        } else {
            require(correct, "wallet address must be correct with wallet name!");
        }

        DepositWithdraw deposWithdr = DepositWithdraw(_deposit);
         
        if (_value > _balance) {
            require(deposWithdr.checkWithdrawAmount(address(params), _value, _time));
            if(_balance > 0) {
                require(deposWithdr.withdrawToken(address(tk), address(walletStorage), _balance));
            }

            require(withdrawFromThis(deposWithdr, _time, _to, _value));
             
        } else {
            require(deposWithdr.withdrawToken(address(tk), address(params), _time, _to, _value, params.chargeFee(), params.chargeFeePool()));
        }

        return walletStorage.decreaseBalance(_deposit, _value);
    }

     
    function destroyDepositContract(address _deposit) onlyOwner public returns (bool) {
        require(_deposit != address(0));

        DepositWithdraw deposWithdr = DepositWithdraw(_deposit);
        address[] memory tokens = new address[](1);
        tokens[0] = address(tk);
        deposWithdr.destroy(tokens);

        return walletStorage.removeDeposit(_deposit);
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}