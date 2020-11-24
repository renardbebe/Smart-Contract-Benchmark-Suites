 

pragma solidity ^0.4.18;
contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
}
contract LocalEthereumEscrows {
     
     
    address public arbitrator;
    address public owner;
    address public relayer;
    uint32 public requestCancellationMinimumTime;
    uint256 public feesAvailableForWithdraw;

    uint8 constant ACTION_SELLER_CANNOT_CANCEL = 0x01;  
    uint8 constant ACTION_BUYER_CANCEL = 0x02;
    uint8 constant ACTION_SELLER_CANCEL = 0x03;
    uint8 constant ACTION_SELLER_REQUEST_CANCEL = 0x04;
    uint8 constant ACTION_RELEASE = 0x05;
    uint8 constant ACTION_DISPUTE = 0x06;

    event Created(bytes32 _tradeHash);
    event SellerCancelDisabled(bytes32 _tradeHash);
    event SellerRequestedCancel(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event DisputeResolved(bytes32 _tradeHash);

    struct Escrow {
         
        bool exists;
         
         
        uint32 sellerCanCancelAfter;
         
         
        uint128 totalGasFeesSpentByRelayer;
    }
     
    mapping (bytes32 => Escrow) public escrows;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator);
        _;
    }

    function getRelayedSender(
      bytes16 _tradeID,  
      uint8 _actionByte,  
      uint128 _maximumGasPrice,  
      uint8 _v,  
      bytes32 _r,  
      bytes32 _s  
    ) view private returns (address) {
        bytes32 _hash = keccak256(_tradeID, _actionByte, _maximumGasPrice);
        if(tx.gasprice > _maximumGasPrice) return;
        return ecrecover(_hash, _v, _r, _s);
    }

    function LocalEthereumEscrows() public {
         
        owner = msg.sender;
        arbitrator = msg.sender;
        relayer = msg.sender;
        requestCancellationMinimumTime = 2 hours;  
    }

    function getEscrowAndHash(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) view private returns (Escrow, bytes32) {
        bytes32 _tradeHash = keccak256(_tradeID, _seller, _buyer, _value, _fee);
        return (escrows[_tradeHash], _tradeHash);
    }

    function createEscrow(
       
      bytes16 _tradeID,  
      address _seller,  
      address _buyer,  
      uint256 _value,  
      uint16 _fee,  
      uint32 _paymentWindowInSeconds,  
      uint32 _expiry,  
      uint8 _v,  
      bytes32 _r,  
      bytes32 _s  
    ) payable external {
        bytes32 _tradeHash = keccak256(_tradeID, _seller, _buyer, _value, _fee);
        require(!escrows[_tradeHash].exists);  
        require(ecrecover(keccak256(_tradeHash, _paymentWindowInSeconds, _expiry), _v, _r, _s) == relayer);  
        require(block.timestamp < _expiry);
        require(msg.value == _value && msg.value > 0);  
        uint32 _sellerCanCancelAfter = _paymentWindowInSeconds == 0 ? 1 : uint32(block.timestamp) + _paymentWindowInSeconds;
        escrows[_tradeHash] = Escrow(true, _sellerCanCancelAfter, 0);
        Created(_tradeHash);
    }

    uint16 constant GAS_doRelease = 36100;
    function doRelease(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? GAS_doRelease + _additionalGas : 0);
        delete escrows[_tradeHash];
        Released(_tradeHash);
        transferMinusFees(_buyer, _value, _gasFees, _fee);
        return true;
    }

    uint16 constant GAS_doDisableSellerCancel = 12100;
    function doDisableSellerCancel(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter == 0) return false;
        escrows[_tradeHash].sellerCanCancelAfter = 0;
        SellerCancelDisabled(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doDisableSellerCancel + _additionalGas);
        }
        return true;
    }

    uint16 constant GAS_doBuyerCancel = 36100;
    function doBuyerCancel(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? GAS_doBuyerCancel + _additionalGas : 0);
        delete escrows[_tradeHash];
        CancelledByBuyer(_tradeHash);
        transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }

    uint16 constant GAS_doSellerCancel = 36100;
    function doSellerCancel(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter <= 1 || _escrow.sellerCanCancelAfter > block.timestamp) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? GAS_doSellerCancel + _additionalGas : 0);
        delete escrows[_tradeHash];
        CancelledBySeller(_tradeHash);
        transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }

    uint16 constant GAS_doSellerRequestCancel = 12100;
    function doSellerRequestCancel(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
         
        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter != 1) return false;
        escrows[_tradeHash].sellerCanCancelAfter = uint32(block.timestamp) + requestCancellationMinimumTime;
        SellerRequestedCancel(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doSellerRequestCancel + _additionalGas);
        }
        return true;
    }

    uint16 constant GAS_doResolveDispute = 36100;
    function resolveDispute(
       
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint8 _buyerPercent
    ) external onlyArbitrator {
        address _signature = ecrecover(keccak256(_tradeID, ACTION_DISPUTE), _v, _r, _s);
        require(_signature == _buyer || _signature == _seller);

        var (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists);
        require(_buyerPercent <= 100);

        uint256 _totalFees = _escrow.totalGasFeesSpentByRelayer + GAS_doResolveDispute;
        require(_value - _totalFees <= _value);  
        feesAvailableForWithdraw += _totalFees;  

        delete escrows[_tradeHash];
        DisputeResolved(_tradeHash);
        _buyer.transfer((_value - _totalFees) * _buyerPercent / 100);
        _seller.transfer((_value - _totalFees) * (100 - _buyerPercent) / 100);
    }

    function release(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool){
      require(msg.sender == _seller);
      return doRelease(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function disableSellerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer);
      return doDisableSellerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function buyerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer);
      return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function sellerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _seller);
      return doSellerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function sellerRequestCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _seller);
      return doSellerRequestCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    function relaySellerCannotCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_SELLER_CANNOT_CANCEL, 0);
    }
    function relayBuyerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_BUYER_CANCEL, 0);
    }
    function relayRelease(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_RELEASE, 0);
    }
    function relaySellerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_SELLER_CANCEL, 0);
    }
    function relaySellerRequestCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_SELLER_REQUEST_CANCEL, 0);
    }

    function relay(
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _maximumGasPrice,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint8 _actionByte,
      uint128 _additionalGas
    ) private returns (bool) {
      address _relayedSender = getRelayedSender(_tradeID, _actionByte, _maximumGasPrice, _v, _r, _s);
      if (_relayedSender == _buyer) {
        if (_actionByte == ACTION_SELLER_CANNOT_CANCEL) {
          return doDisableSellerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_BUYER_CANCEL) {
          return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        }
      } else if (_relayedSender == _seller) {
        if (_actionByte == ACTION_RELEASE) {
          return doRelease(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_SELLER_CANCEL) {
          return doSellerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_SELLER_REQUEST_CANCEL){
          return doSellerRequestCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        }
      } else {
        return false;
      }
    }

    uint16 constant GAS_batchRelayBaseCost = 28500;
    function batchRelay(
       
        bytes16[] _tradeID,
        address[] _seller,
        address[] _buyer,
        uint256[] _value,
        uint16[] _fee,
        uint128[] _maximumGasPrice,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s,
        uint8[] _actionByte
    ) public returns (bool[]) {
        bool[] memory _results = new bool[](_tradeID.length);
        uint128 _additionalGas = uint128(msg.sender == relayer ? GAS_batchRelayBaseCost / _tradeID.length : 0);
        for (uint8 i=0; i<_tradeID.length; i++) {
            _results[i] = relay(_tradeID[i], _seller[i], _buyer[i], _value[i], _fee[i], _maximumGasPrice[i], _v[i], _r[i], _s[i], _actionByte[i], _additionalGas);
        }
        return _results;
    }

    function increaseGasSpent(bytes32 _tradeHash, uint128 _gas) private {
         
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _gas * uint128(tx.gasprice);
    }

    function transferMinusFees(address _to, uint256 _value, uint128 _totalGasFeesSpentByRelayer, uint16 _fee) private {
        uint256 _totalFees = (_value * _fee / 10000) + _totalGasFeesSpentByRelayer;
        if(_value - _totalFees > _value) return;  
        feesAvailableForWithdraw += _totalFees;  
        _to.transfer(_value - _totalFees);
    }

    function withdrawFees(address _to, uint256 _amount) onlyOwner external {
       
        require(_amount <= feesAvailableForWithdraw);  
        feesAvailableForWithdraw -= _amount;
        _to.transfer(_amount);
    }

    function setArbitrator(address _newArbitrator) onlyOwner external {
         
        arbitrator = _newArbitrator;
    }

    function setOwner(address _newOwner) onlyOwner external {
         
        owner = _newOwner;
    }

    function setRelayer(address _newRelayer) onlyOwner external {
         
        relayer = _newRelayer;
    }

    function setRequestCancellationMinimumTime(uint32 _newRequestCancellationMinimumTime) onlyOwner external {
         
        requestCancellationMinimumTime = _newRequestCancellationMinimumTime;
    }

    function transferToken(Token _tokenContract, address _transferTo, uint256 _value) onlyOwner external {
         
         _tokenContract.transfer(_transferTo, _value);
    }
    function transferTokenFrom(Token _tokenContract, address _transferTo, address _transferFrom, uint256 _value) onlyOwner external {
         
         _tokenContract.transferFrom(_transferTo, _transferFrom, _value);
    }
    function approveToken(Token _tokenContract, address _spender, uint256 _value) onlyOwner external {
         
         _tokenContract.approve(_spender, _value);
    }
}