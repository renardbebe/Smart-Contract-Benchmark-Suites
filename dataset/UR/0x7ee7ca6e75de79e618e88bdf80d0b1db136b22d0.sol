 

 

pragma solidity 0.5.12;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity 0.5.12;

 
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
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

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity 0.5.12;


interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface MarketDapp {
     
    function tokenReceiver(address[] calldata assetIds, uint256[] calldata dataValues, address[] calldata addresses) external view returns(address);
    function trade(address[] calldata assetIds, uint256[] calldata dataValues, address[] calldata addresses, address payable recipient) external payable;
}

 
 
 
 
 
library Utils {
    using SafeMath for uint256;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
    bytes32 public constant DOMAIN_SEPARATOR = 0x256c0713d13c6a01bd319a2f7edabde771b6c167d37c01778290d60b362ccc7d;

     
     
     
     
     
     
     
     
     
     
     
     
    bytes32 public constant OFFER_TYPEHASH = 0xf845c83a8f7964bc8dd1a092d28b83573b35be97630a5b8a3b8ae2ae79cd9260;

     
     
     
     
     
     
     
    bytes32 public constant CANCEL_TYPEHASH = 0x46f6d088b1f0ff5a05c3f232c4567f2df96958e05457e6c0e1221dcee7d69c18;

     
     
     
     
     
     
     
     
     
     
     
     
    bytes32 public constant FILL_TYPEHASH = 0x5f59dbc3412a4575afed909d028055a91a4250ce92235f6790c155a4b2669e99;

     
     
    address private constant ETHER_ADDR = address(0);

    uint256 private constant mask8 = ~(~uint256(0) << 8);
    uint256 private constant mask16 = ~(~uint256(0) << 16);
    uint256 private constant mask24 = ~(~uint256(0) << 24);
    uint256 private constant mask32 = ~(~uint256(0) << 32);
    uint256 private constant mask40 = ~(~uint256(0) << 40);
    uint256 private constant mask48 = ~(~uint256(0) << 48);
    uint256 private constant mask56 = ~(~uint256(0) << 56);
    uint256 private constant mask120 = ~(~uint256(0) << 120);
    uint256 private constant mask128 = ~(~uint256(0) << 128);
    uint256 private constant mask136 = ~(~uint256(0) << 136);
    uint256 private constant mask144 = ~(~uint256(0) << 144);

    event Trade(
        address maker,
        address taker,
        address makerGiveAsset,
        uint256 makerGiveAmount,
        address fillerGiveAsset,
        uint256 fillerGiveAmount
    );

     
     
     
     
     
    function calculateTradeIncrements(
        uint256[] memory _values,
        uint256 _incrementsLength
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory increments = new uint256[](_incrementsLength);
        _creditFillBalances(increments, _values);
        _creditMakerBalances(increments, _values);
        _creditMakerFeeBalances(increments, _values);
        return increments;
    }

     
     
     
     
     
    function calculateTradeDecrements(
        uint256[] memory _values,
        uint256 _decrementsLength
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory decrements = new uint256[](_decrementsLength);
        _deductFillBalances(decrements, _values);
        _deductMakerBalances(decrements, _values);
        return decrements;
    }

     
     
     
     
     
    function calculateNetworkTradeIncrements(
        uint256[] memory _values,
        uint256 _incrementsLength
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory increments = new uint256[](_incrementsLength);
        _creditMakerBalances(increments, _values);
        _creditMakerFeeBalances(increments, _values);
        return increments;
    }

     
     
     
     
     
    function calculateNetworkTradeDecrements(
        uint256[] memory _values,
        uint256 _decrementsLength
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory decrements = new uint256[](_decrementsLength);
        _deductMakerBalances(decrements, _values);
        return decrements;
    }

     
     
     
     
     
    function validateTrades(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses,
        address _operator
    )
        public
        returns (bytes32[] memory)
    {
        _validateTradeInputLengths(_values, _hashes);
        _validateUniqueOffers(_values);
        _validateMatches(_values, _addresses);
        _validateFillAmounts(_values);
        _validateTradeData(_values, _addresses, _operator);

         
        _validateTradeSignatures(
            _values,
            _hashes,
            _addresses,
            OFFER_TYPEHASH,
            0,
            _values[0] & mask8  
        );

         
        _validateTradeSignatures(
            _values,
            _hashes,
            _addresses,
            FILL_TYPEHASH,
            _values[0] & mask8,  
            (_values[0] & mask8) + ((_values[0] & mask16) >> 8)  
        );

        _emitTradeEvents(_values, _addresses, new address[](0), false);

        return _hashes;
    }

     
     
     
     
     
     
    function validateNetworkTrades(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses,
        address _operator
    )
        public
        pure
        returns (bytes32[] memory)
    {
        _validateNetworkTradeInputLengths(_values, _hashes);
        _validateUniqueOffers(_values);
        _validateNetworkMatches(_values, _addresses, _operator);
        _validateTradeData(_values, _addresses, _operator);

         
        _validateTradeSignatures(
            _values,
            _hashes,
            _addresses,
            OFFER_TYPEHASH,
            0,
            _values[0] & mask8  
        );

        return _hashes;
    }

     
     
     
     
     
    function performNetworkTrades(
        uint256[] memory _values,
        address[] memory _addresses,
        address[] memory _marketDapps
    )
        public
        returns (uint256[] memory)
    {
        uint256[] memory increments = new uint256[](_addresses.length / 2);
         
        uint256 i = 1 + (_values[0] & mask8) * 2;
        uint256 end = _values.length;

         
        for(i; i < end; i++) {
            uint256[] memory data = new uint256[](9);
            data[0] = _values[i];  
            data[1] = data[0] & mask8;  
            data[2] = (data[0] & mask24) >> 16;  
            data[3] = _values[data[1] * 2 + 1];  
            data[4] = _values[data[1] * 2 + 2];  
            data[5] = ((data[3] & mask16) >> 8);  
            data[6] = ((data[3] & mask24) >> 16);  
             
            data[7] = data[0] >> 128;
             
            data[8] = data[7].mul(data[4] >> 128).div(data[4] & mask128);

            address[] memory assetIds = new address[](3);
            assetIds[0] = _addresses[data[5] * 2 + 1];  
            assetIds[1] = _addresses[data[6] * 2 + 1];  
            assetIds[2] = _addresses[data[2] * 2 + 1];  

            uint256[] memory dataValues = new uint256[](3);
            dataValues[0] = data[7];  
            dataValues[1] = data[8];  
            dataValues[2] = data[0];  

            increments[data[2]] = _performNetworkTrade(
                assetIds,
                dataValues,
                _marketDapps,
                _addresses
            );
        }

        _emitTradeEvents(_values, _addresses, _marketDapps, true);

        return increments;
    }

     
     
     
     
    function validateCancel(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses
    )
        public
        pure
    {
        bytes32 offerHash = hashOffer(_values, _addresses);

        bytes32 cancelHash = keccak256(abi.encode(
            CANCEL_TYPEHASH,
            offerHash,
            _addresses[4],
            _values[1] >> 128
        ));

        validateSignature(
            cancelHash,
            _addresses[0],  
            uint8((_values[2] & mask144) >> 136),  
            _hashes[0],  
            _hashes[1],  
            ((_values[2] & mask136) >> 128) != 0  
        );
    }

     
     
     
     
    function hashOffer(
        uint256[] memory _values,
        address[] memory _addresses
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            OFFER_TYPEHASH,
            _addresses[0],  
            _addresses[1],  
            _values[0] & mask128,  
            _addresses[2],  
            _values[0] >> 128,  
            _addresses[3],  
            _values[1] & mask128,  
            _values[2] >> 144  
        ));
    }

     
     
     
     
    function approveTokenTransfer(
        address _assetId,
        address _spender,
        uint256 _amount
    )
        public
    {
        _validateContractAddress(_assetId);

         
         
         
         
        bytes memory payload = abi.encodeWithSignature(
            "approve(address,uint256)",
            _spender,
            _amount
        );
        bytes memory returnData = _callContract(_assetId, payload);
         
        _validateContractCallResult(returnData);
    }

     
     
     
     
     
     
     
    function transferTokensIn(
        address _user,
        address _assetId,
        uint256 _amount,
        uint256 _expectedAmount
    )
        public
    {
        _validateContractAddress(_assetId);

        uint256 initialBalance = tokenBalance(_assetId);

         
         
         
         
        bytes memory payload = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            _user,
            address(this),
            _amount
        );
        bytes memory returnData = _callContract(_assetId, payload);
         
        _validateContractCallResult(returnData);

        uint256 finalBalance = tokenBalance(_assetId);
        uint256 transferredAmount = finalBalance.sub(initialBalance);

        require(transferredAmount == _expectedAmount, "Invalid transfer");
    }

     
     
     
     
    function transferTokensOut(
        address _receivingAddress,
        address _assetId,
        uint256 _amount
    )
        public
    {
        _validateContractAddress(_assetId);

         
         
         
         
        bytes memory payload = abi.encodeWithSignature(
                                   "transfer(address,uint256)",
                                   _receivingAddress,
                                   _amount
                               );
        bytes memory returnData = _callContract(_assetId, payload);

         
        _validateContractCallResult(returnData);
    }

     
     
    function externalBalance(address _assetId) public view returns (uint256) {
        if (_assetId == ETHER_ADDR) {
            return address(this).balance;
        }
        return tokenBalance(_assetId);
    }

     
     
     
     
    function tokenBalance(address _assetId) public view returns (uint256) {
        return ERC20(_assetId).balanceOf(address(this));
    }

     
     
     
     
     
     
     
     
     
     
     
    function validateSignature(
        bytes32 _hash,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bool _prefixed
    )
        public
        pure
    {
        bytes32 eip712Hash = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            _hash
        ));

        if (_prefixed) {
            bytes32 prefixedHash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                eip712Hash
            ));
            require(_user == ecrecover(prefixedHash, _v, _r, _s), "Invalid signature");
        } else {
            require(_user == ecrecover(eip712Hash, _v, _r, _s), "Invalid signature");
        }
    }

     
     
    function validateAddress(address _address) public pure {
        require(_address != address(0), "Invalid address");
    }

     
     
     
    function _creditFillBalances(
        uint256[] memory _increments,
        uint256[] memory _values
    )
        private
        pure
    {
         
        uint256 i = 1 + (_values[0] & mask8) * 2;
         
        uint256 end = i + ((_values[0] & mask16) >> 8) * 2;

         
        for(i; i < end; i += 2) {
            uint256 fillerWantAssetIndex = (_values[i] & mask24) >> 16;
            uint256 wantAmount = _values[i + 1] >> 128;

             
            _increments[fillerWantAssetIndex] = _increments[fillerWantAssetIndex].add(wantAmount);

            uint256 feeAmount = _values[i] >> 128;
            if (feeAmount == 0) { continue; }

            uint256 operatorFeeAssetIndex = ((_values[i] & mask40) >> 32);
             
            _increments[operatorFeeAssetIndex] = _increments[operatorFeeAssetIndex].add(feeAmount);
        }
    }

     
     
     
    function _creditMakerBalances(
        uint256[] memory _increments,
        uint256[] memory _values
    )
        private
        pure
    {
        uint256 i = 1;
         
        i += (_values[0] & mask8) * 2;
         
        i += ((_values[0] & mask16) >> 8) * 2;

        uint256 end = _values.length;

         
        for(i; i < end; i++) {
             
            uint256 offerIndex = _values[i] & mask8;
             
            uint256 makerWantAssetIndex = (_values[1 + offerIndex * 2] & mask24) >> 16;

             
            uint256 amount = _values[i] >> 128;
             
            amount = amount.mul(_values[2 + offerIndex * 2] >> 128)
                           .div(_values[2 + offerIndex * 2] & mask128);

             
            _increments[makerWantAssetIndex] = _increments[makerWantAssetIndex].add(amount);
        }
    }

     
     
     
     
    function _creditMakerFeeBalances(
        uint256[] memory _increments,
        uint256[] memory _values
    )
        private
        pure
    {
        uint256 i = 1;
         
        uint256 end = i + (_values[0] & mask8) * 2;

         
        for(i; i < end; i += 2) {
            bool nonceTaken = ((_values[i] & mask128) >> 120) == 1;
            if (nonceTaken) { continue; }

            uint256 feeAmount = _values[i] >> 128;
            if (feeAmount == 0) { continue; }

            uint256 operatorFeeAssetIndex = (_values[i] & mask40) >> 32;

             
            _increments[operatorFeeAssetIndex] = _increments[operatorFeeAssetIndex].add(feeAmount);
        }
    }

     
     
     
     
    function _deductFillBalances(
        uint256[] memory _decrements,
        uint256[] memory _values
    )
        private
        pure
    {
         
        uint256 i = 1 + (_values[0] & mask8) * 2;
         
        uint256 end = i + ((_values[0] & mask16) >> 8) * 2;

         
        for(i; i < end; i += 2) {
            uint256 fillerOfferAssetIndex = (_values[i] & mask16) >> 8;
            uint256 offerAmount = _values[i + 1] & mask128;

             
            _decrements[fillerOfferAssetIndex] = _decrements[fillerOfferAssetIndex].add(offerAmount);

            uint256 feeAmount = _values[i] >> 128;
            if (feeAmount == 0) { continue; }

             
            uint256 fillerFeeAssetIndex = (_values[i] & mask32) >> 24;
            _decrements[fillerFeeAssetIndex] = _decrements[fillerFeeAssetIndex].add(feeAmount);
        }
    }

     
     
     
     
     
    function _deductMakerBalances(
        uint256[] memory _decrements,
        uint256[] memory _values
    )
        private
        pure
    {
        uint256 i = 1;
         
        uint256 end = i + (_values[0] & mask8) * 2;

         
        for(i; i < end; i += 2) {
            bool nonceTaken = ((_values[i] & mask128) >> 120) == 1;
            if (nonceTaken) { continue; }

            uint256 makerOfferAssetIndex = (_values[i] & mask16) >> 8;
            uint256 offerAmount = _values[i + 1] & mask128;

             
            _decrements[makerOfferAssetIndex] = _decrements[makerOfferAssetIndex].add(offerAmount);

            uint256 feeAmount = _values[i] >> 128;
            if (feeAmount == 0) { continue; }

             
            uint256 makerFeeAssetIndex = (_values[i] & mask32) >> 24;
            _decrements[makerFeeAssetIndex] = _decrements[makerFeeAssetIndex].add(feeAmount);
        }
    }

     
     
     
     
     
    function _emitTradeEvents(
        uint256[] memory _values,
        address[] memory _addresses,
        address[] memory _marketDapps,
        bool _forNetworkTrade
    )
        private
    {
        uint256 i = 1;
         
        i += (_values[0] & mask8) * 2;
         
        i += ((_values[0] & mask16) >> 8) * 2;

        uint256 end = _values.length;

         
        for(i; i < end; i++) {
            uint256[] memory data = new uint256[](7);
            data[0] = _values[i] & mask8;  
            data[1] = _values[1 + data[0] * 2] & mask8;  
            data[2] = (_values[1 + data[0] * 2] & mask16) >> 8;  
            data[3] = (_values[1 + data[0] * 2] & mask24) >> 16;  
            data[4] = _values[i] >> 128;  
             
            data[5] = data[4].mul(_values[2 + data[0] * 2] >> 128)
                             .div(_values[2 + data[0] * 2] & mask128);
             
            data[6] = (_values[i] & mask16) >> 8;

            address filler;
            if (_forNetworkTrade) {
                filler = _marketDapps[data[6]];
            } else {
                uint256 fillerIndex = (_values[1 + data[6] * 2] & mask8);
                filler = _addresses[fillerIndex * 2];
            }

            emit Trade(
                _addresses[data[1] * 2],  
                filler,
                _addresses[data[2] * 2 + 1],  
                data[4],  
                _addresses[data[3] * 2 + 1],  
                data[5]  
            );
        }
    }


     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _performNetworkTrade(
        address[] memory _assetIds,
        uint256[] memory _dataValues,
        address[] memory _marketDapps,
        address[] memory _addresses
    )
        private
        returns (uint256)
    {
        uint256 dappIndex = (_dataValues[2] & mask16) >> 8;
        validateAddress(_marketDapps[dappIndex]);
        MarketDapp marketDapp = MarketDapp(_marketDapps[dappIndex]);

        uint256[] memory funds = new uint256[](6);
        funds[0] = externalBalance(_assetIds[0]);  
        funds[1] = externalBalance(_assetIds[1]);  
        if (_assetIds[2] != _assetIds[0] && _assetIds[2] != _assetIds[1]) {
            funds[2] = externalBalance(_assetIds[2]);  
        }

        uint256 ethValue = 0;
        address tokenReceiver;

        if (_assetIds[0] == ETHER_ADDR) {
            ethValue = _dataValues[0];  
        } else {
            tokenReceiver = marketDapp.tokenReceiver(_assetIds, _dataValues, _addresses);
            approveTokenTransfer(
                _assetIds[0],  
                tokenReceiver,
                _dataValues[0]  
            );
        }

        marketDapp.trade.value(ethValue)(
            _assetIds,
            _dataValues,
            _addresses,
             
            address(uint160(address(this)))  
        );

        funds[3] = externalBalance(_assetIds[0]);  
        funds[4] = externalBalance(_assetIds[1]);  
        if (_assetIds[2] != _assetIds[0] && _assetIds[2] != _assetIds[1]) {
            funds[5] = externalBalance(_assetIds[2]);  
        }

        uint256 surplusAmount = 0;

         
         
        if (_assetIds[2] == _assetIds[0]) {
             
            surplusAmount = funds[3].sub(funds[0].sub(_dataValues[0]));
        } else {
             
            require(funds[3] == funds[0].sub(_dataValues[0]), "Invalid offer asset balance");
        }

         
         
        if (_assetIds[2] == _assetIds[1]) {
             
            surplusAmount = funds[4].sub(funds[1].add(_dataValues[1]));
        } else {
             
            require(funds[4] == funds[1].add(_dataValues[1]), "Invalid want asset balance");
        }

         
        if (_assetIds[2] != _assetIds[0] && _assetIds[2] != _assetIds[1]) {
             
            surplusAmount = funds[5].sub(funds[2]);
        }

         
        if (_assetIds[0] != ETHER_ADDR) {
            approveTokenTransfer(
                _assetIds[0],
                tokenReceiver,
                0
            );
        }

        return surplusAmount;
    }

     
     
     
     
    function _validateTradeInputLengths(
        uint256[] memory _values,
        bytes32[] memory _hashes
    )
        private
        pure
    {
        uint256 numOffers = _values[0] & mask8;
        uint256 numFills = (_values[0] & mask16) >> 8;
        uint256 numMatches = (_values[0] & mask24) >> 16;

         
        require(_values[0] >> 24 == 0, "Invalid trade input");

         
         
         
         
         
         
        require(
            numOffers > 0 && numFills > 0 && numMatches > 0,
            "Invalid trade input"
        );

        require(
            _values.length == 1 + numOffers * 2 + numFills * 2 + numMatches,
            "Invalid _values.length"
        );

        require(
            _hashes.length == (numOffers + numFills) * 2,
            "Invalid _hashes.length"
        );
    }

     
     
     
     
    function _validateNetworkTradeInputLengths(
        uint256[] memory _values,
        bytes32[] memory _hashes
    )
        private
        pure
    {
        uint256 numOffers = _values[0] & mask8;
        uint256 numFills = (_values[0] & mask16) >> 8;
        uint256 numMatches = (_values[0] & mask24) >> 16;

         
        require(_values[0] >> 24 == 0, "Invalid networkTrade input");

         
         
        require(
            numOffers > 0 && numMatches > 0 && numFills == 0,
            "Invalid networkTrade input"
        );

        require(
            _values.length == 1 + numOffers * 2 + numMatches,
            "Invalid _values.length"
        );

        require(
            _hashes.length == numOffers * 2,
            "Invalid _hashes.length"
        );
    }

     
     
     
     
     
     
     
    function _validateUniqueOffers(uint256[] memory _values) private pure {
        uint256 numOffers = _values[0] & mask8;

        uint256 prevNonce;

        for(uint256 i = 0; i < numOffers; i++) {
            uint256 nonce = (_values[i * 2 + 1] & mask120) >> 56;

            if (i == 0) {
                 
                prevNonce = nonce;
                continue;
            }

            require(nonce > prevNonce, "Invalid offer nonces");
            prevNonce = nonce;
        }
    }

     
     
     
     
     
     
     
     
     
    function _validateMatches(
        uint256[] memory _values,
        address[] memory _addresses
    )
        private
        pure
    {
        uint256 numOffers = _values[0] & mask8;
        uint256 numFills = (_values[0] & mask16) >> 8;

        uint256 i = 1 + numOffers * 2 + numFills * 2;
        uint256 end = _values.length;

         
        for (i; i < end; i++) {
            uint256 offerIndex = _values[i] & mask8;
            uint256 fillIndex = (_values[i] & mask16) >> 8;

            require(offerIndex < numOffers, "Invalid match.offerIndex");

            require(fillIndex >= numOffers && fillIndex < numOffers + numFills, "Invalid match.fillIndex");

            require(
                _addresses[_values[1 + offerIndex * 2] & mask8] !=
                _addresses[_values[1 + fillIndex * 2] & mask8],
                "offer.maker cannot be the same as fill.filler"
            );

            uint256 makerOfferAssetIndex = (_values[1 + offerIndex * 2] & mask16) >> 8;
            uint256 makerWantAssetIndex = (_values[1 + offerIndex * 2] & mask24) >> 16;
            uint256 fillerOfferAssetIndex = (_values[1 + fillIndex * 2] & mask16) >> 8;
            uint256 fillerWantAssetIndex = (_values[1 + fillIndex * 2] & mask24) >> 16;

            require(
                _addresses[makerOfferAssetIndex * 2 + 1] ==
                _addresses[fillerWantAssetIndex * 2 + 1],
                "offer.offerAssetId does not match fill.wantAssetId"
            );

            require(
                _addresses[makerWantAssetIndex * 2 + 1] ==
                _addresses[fillerOfferAssetIndex * 2 + 1],
                "offer.wantAssetId does not match fill.offerAssetId"
            );

             
            require((_values[i] & mask128) >> 16 == uint256(0), "Invalid match data");

            uint256 takeAmount = _values[i] >> 128;
            require(takeAmount > 0, "Invalid match.takeAmount");

            uint256 offerDataB = _values[2 + offerIndex * 2];
             
            require(
                (offerDataB >> 128).mul(takeAmount).mod(offerDataB & mask128) == 0,
                "Invalid amounts"
            );
        }
    }

     
     
     
     
     
     
     
     
    function _validateNetworkMatches(
        uint256[] memory _values,
        address[] memory _addresses,
        address _operator
    )
        private
        pure
    {
        uint256 numOffers = _values[0] & mask8;

         
        uint256 i = 1 + (_values[0] & mask8) * 2;
        uint256 end = _values.length;

         
        for (i; i < end; i++) {
            uint256 offerIndex = _values[i] & mask8;
            uint256 surplusAssetIndex = (_values[i] & mask24) >> 16;

            require(offerIndex < numOffers, "Invalid match.offerIndex");
            require(_addresses[surplusAssetIndex * 2] == _operator, "Invalid operator address");

            uint256 takeAmount = _values[i] >> 128;
            require(takeAmount > 0, "Invalid match.takeAmount");

            uint256 offerDataB = _values[2 + offerIndex * 2];
             
            require(
                (offerDataB >> 128).mul(takeAmount).mod(offerDataB & mask128) == 0,
                "Invalid amounts"
            );
        }
    }

     
     
     
     
    function _validateFillAmounts(uint256[] memory _values) private pure {
         
         
         
         
         
         
        uint256[] memory filled = new uint256[](_values.length);

        uint256 i = 1;
         
        i += (_values[0] & mask8) * 2;
         
        i += ((_values[0] & mask16) >> 8) * 2;

        uint256 end = _values.length;

         
        for (i; i < end; i++) {
            uint256 offerIndex = _values[i] & mask8;
            uint256 fillIndex = (_values[i] & mask16) >> 8;
            uint256 takeAmount = _values[i] >> 128;
            uint256 wantAmount = _values[2 + offerIndex * 2] >> 128;
            uint256 offerAmount = _values[2 + offerIndex * 2] & mask128;
             
            uint256 giveAmount = takeAmount.mul(wantAmount).div(offerAmount);

             
             
             
            filled[1 + fillIndex * 2] = filled[1 + fillIndex * 2].add(giveAmount);
            filled[2 + fillIndex * 2] = filled[2 + fillIndex * 2].add(takeAmount);
        }

         
        i = _values[0] & mask8;
         
        end = i + ((_values[0] & mask16) >> 8);

         
        for(i; i < end; i++) {
            require(
                 
                _values[i * 2 + 2] & mask128 == filled[i * 2 + 1] &&
                 
                _values[i * 2 + 2] >> 128 == filled[i * 2 + 2],
                "Invalid fills"
            );
        }
    }

     
     
     
     
     
     
     
     
     
     
    function _validateTradeData(
        uint256[] memory _values,
        address[] memory _addresses,
        address _operator
    )
        private
        pure
    {
         
        uint256 end = (_values[0] & mask8) +
                      ((_values[0] & mask16) >> 8);

        for (uint256 i = 0; i < end; i++) {
            uint256 dataA = _values[i * 2 + 1];
            uint256 dataB = _values[i * 2 + 2];
            uint256 feeAssetIndex = ((dataA & mask40) >> 32) * 2;

            require(
                 
                _addresses[(dataA & mask8) * 2] ==
                _addresses[((dataA & mask16) >> 8) * 2],
                "Invalid user in user.offerAssetIndex"
            );

            require(
                 
                _addresses[(dataA & mask8) * 2] ==
                _addresses[((dataA & mask24) >> 16) * 2],
                "Invalid user in user.wantAssetIndex"
            );

            require(
                 
                _addresses[(dataA & mask8) * 2] ==
                _addresses[((dataA & mask32) >> 24) * 2],
                "Invalid user in user.feeAssetIndex"
            );

            require(
                 
                _addresses[((dataA & mask16) >> 8) * 2 + 1] !=
                _addresses[((dataA & mask24) >> 16) * 2 + 1],
                "Invalid trade assets"
            );

            require(
                 
                (dataB & mask128) > 0 && (dataB >> 128) > 0,
                "Invalid trade amounts"
            );

             require(
                _addresses[feeAssetIndex] == _operator,
                "Invalid operator address"
            );

             require(
                _addresses[feeAssetIndex + 1] ==
                _addresses[((dataA & mask32) >> 24) * 2 + 1],
                "Invalid operator fee asset ID"
            );
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function _validateTradeSignatures(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses,
        bytes32 _typehash,
        uint256 _i,
        uint256 _end
    )
        private
        pure
    {
        for (_i; _i < _end; _i++) {
            uint256 dataA = _values[_i * 2 + 1];
            uint256 dataB = _values[_i * 2 + 2];

            bytes32 hashKey = keccak256(abi.encode(
                _typehash,
                _addresses[(dataA & mask8) * 2],  
                _addresses[((dataA & mask16) >> 8) * 2 + 1],  
                dataB & mask128,  
                _addresses[((dataA & mask24) >> 16) * 2 + 1],  
                dataB >> 128,  
                _addresses[((dataA & mask32) >> 24) * 2 + 1],  
                dataA >> 128,  
                (dataA & mask120) >> 56  
            ));

            bool prefixedSignature = ((dataA & mask56) >> 48) != 0;

            validateSignature(
                hashKey,
                _addresses[(dataA & mask8) * 2],  
                uint8((dataA & mask48) >> 40),  
                _hashes[_i * 2],  
                _hashes[_i * 2 + 1],  
                prefixedSignature
            );

            _hashes[_i * 2] = hashKey;
        }
    }

     
     
    function _validateContractAddress(address _contract) private view {
        assembly {
            if iszero(extcodesize(_contract)) { revert(0, 0) }
        }
    }

     
     
     
     
     
     
     
    function _callContract(
        address _contract,
        bytes memory _payload
    )
        private
        returns (bytes memory)
    {
        bool success;
        bytes memory returnData;

        (success, returnData) = _contract.call(_payload);
        require(success, "Contract call failed");

        return returnData;
    }

     
     
     
     
     
    function _validateContractCallResult(bytes memory _data) private pure {
        require(
            _data.length == 0 ||
            (_data.length == 32 && _getUint256FromBytes(_data) != 0),
            "Invalid contract call result"
        );
    }

     
     
     
    function _getUint256FromBytes(
        bytes memory _data
    )
        private
        pure
        returns (uint256)
    {
        uint256 parsed;
        assembly { parsed := mload(add(_data, 32)) }
        return parsed;
    }
}

 

pragma solidity 0.5.12;





interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
}

interface TokenList {
    function validateToken(address assetId) external view;
}

interface SpenderList {
    function validateSpender(address spender) external view;
    function validateSpenderAuthorization(address user, address spender) external view;
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract BrokerV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct WithdrawalAnnouncement {
        uint256 amount;
        uint256 withdrawableAt;
    }

     
    enum State { Active, Inactive }
     
    enum AdminState { Normal, Escalated }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    bytes32 public constant WITHDRAW_TYPEHASH = 0xbe2f4292252fbb88b129dc7717b2f3f74a9afb5b13a2283cac5c056117b002eb;

     
     
     
     
     
     
     
     
     
     
     
     
    bytes32 public constant OFFER_TYPEHASH = 0xf845c83a8f7964bc8dd1a092d28b83573b35be97630a5b8a3b8ae2ae79cd9260;

     
     
     
     
     
     
     
     
     
     
     
     
     
    bytes32 public constant SWAP_TYPEHASH = 0x6ba9001457a287c210b728198a424a4222098d7fac48f8c5fb5ab10ef907d3ef;

     
     
    address private constant ETHER_ADDR = address(0);

     
    uint256 private constant MAX_SWAP_SECRET_LENGTH = 64;

     
    uint256 private constant REASON_DEPOSIT = 0x01;

    uint256 private constant REASON_WITHDRAW = 0x09;
    uint256 private constant REASON_WITHDRAW_FEE_GIVE = 0x14;
    uint256 private constant REASON_WITHDRAW_FEE_RECEIVE = 0x15;

    uint256 private constant REASON_CANCEL = 0x08;
    uint256 private constant REASON_CANCEL_FEE_GIVE = 0x12;
    uint256 private constant REASON_CANCEL_FEE_RECEIVE = 0x13;

    uint256 private constant REASON_SWAP_GIVE = 0x30;
    uint256 private constant REASON_SWAP_FEE_GIVE = 0x32;
    uint256 private constant REASON_SWAP_RECEIVE = 0x35;
    uint256 private constant REASON_SWAP_FEE_RECEIVE = 0x37;

    uint256 private constant REASON_SWAP_CANCEL_RECEIVE = 0x38;
    uint256 private constant REASON_SWAP_CANCEL_FEE_RECEIVE = 0x3B;
    uint256 private constant REASON_SWAP_CANCEL_FEE_REFUND = 0x3D;

     
    uint256 private constant MAX_SLOW_WITHDRAW_DELAY = 604800;
    uint256 private constant MAX_SLOW_CANCEL_DELAY = 604800;

    uint256 private constant mask8 = ~(~uint256(0) << 8);
    uint256 private constant mask16 = ~(~uint256(0) << 16);
    uint256 private constant mask24 = ~(~uint256(0) << 24);
    uint256 private constant mask32 = ~(~uint256(0) << 32);
    uint256 private constant mask40 = ~(~uint256(0) << 40);
    uint256 private constant mask120 = ~(~uint256(0) << 120);
    uint256 private constant mask128 = ~(~uint256(0) << 128);
    uint256 private constant mask136 = ~(~uint256(0) << 136);
    uint256 private constant mask144 = ~(~uint256(0) << 144);

    State public state;
    AdminState public adminState;
     
    address public operator;
    TokenList public tokenList;
    SpenderList public spenderList;

     
     
     
    uint256 public slowCancelDelay;
    uint256 public slowWithdrawDelay;

     
    mapping(bytes32 => uint256) public offers;
     
     
     
     
     
     
     
     
    mapping(uint256 => uint256) public usedNonces;
     
    mapping(address => mapping(address => uint256)) public balances;
     
    mapping(bytes32 => bool) public atomicSwaps;

     
    mapping(address => bool) public adminAddresses;
     
    address[] public marketDapps;
     
    mapping(bytes32 => uint256) public cancellationAnnouncements;
     
    mapping(address => mapping(address => WithdrawalAnnouncement)) public withdrawalAnnouncements;

     
    event BalanceIncrease(
        address indexed user,
        address indexed assetId,
        uint256 amount,
        uint256 reason,
        uint256 nonce
    );

     
    event BalanceDecrease(
        address indexed user,
        address indexed assetId,
        uint256 amount,
        uint256 reason,
        uint256 nonce
    );

     
     
    event Increment(uint256 data);
    event Decrement(uint256 data);

    event TokenFallback(
        address indexed user,
        address indexed assetId,
        uint256 amount
    );

    event TokensReceived(
        address indexed user,
        address indexed assetId,
        uint256 amount
    );

    event AnnounceCancel(
        bytes32 indexed offerHash,
        uint256 cancellableAt
    );

    event SlowCancel(
        bytes32 indexed offerHash,
        uint256 amount
    );

    event AnnounceWithdraw(
        address indexed withdrawer,
        address indexed assetId,
        uint256 amount,
        uint256 withdrawableAt
    );

    event SlowWithdraw(
        address indexed withdrawer,
        address indexed assetId,
        uint256 amount
    );

     
     
     
     
     
     
    constructor(address _tokenListAddress, address _spenderListAddress) public {
        adminAddresses[msg.sender] = true;
        operator = msg.sender;
        tokenList = TokenList(_tokenListAddress);
        spenderList = SpenderList(_spenderListAddress);

        slowWithdrawDelay = MAX_SLOW_WITHDRAW_DELAY;
        slowCancelDelay = MAX_SLOW_CANCEL_DELAY;
        state = State.Active;

        IERC1820Registry erc1820 = IERC1820Registry(
            0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
        );

        erc1820.setInterfaceImplementer(
            address(this),
            keccak256("ERC777TokensRecipient"),
            address(this)
        );
    }

    modifier onlyAdmin() {
         
        require(adminAddresses[msg.sender], "1");
        _;
    }

    modifier onlyActiveState() {
         
        require(state == State.Active, "2");
        _;
    }

    modifier onlyEscalatedAdminState() {
         
        require(adminState == AdminState.Escalated, "3");
        _;
    }

     
     
     
    function isAdmin(address _user) external view returns(bool) {
        return adminAddresses[_user];
    }

     
     
     
     
     
     
     
     
    function setState(State _state) external onlyOwner nonReentrant { state = _state; }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function setAdminState(AdminState _state) external onlyOwner nonReentrant { adminState = _state; }

     
     
     
    function setOperator(address _operator) external onlyOwner nonReentrant {
        _validateAddress(operator);
        operator = _operator;
    }

     
     
     
     
     
     
    function setSlowCancelDelay(uint256 _delay) external onlyOwner nonReentrant {
         
        require(_delay <= MAX_SLOW_CANCEL_DELAY, "4");
        slowCancelDelay = _delay;
    }

     
     
     
     
     
     
    function setSlowWithdrawDelay(uint256 _delay) external onlyOwner nonReentrant {
         
        require(_delay <= MAX_SLOW_WITHDRAW_DELAY, "5");
        slowWithdrawDelay = _delay;
    }

     
     
     
     
     
    function addAdmin(address _admin) external onlyOwner nonReentrant {
        _validateAddress(_admin);
         
        require(!adminAddresses[_admin], "6");
        adminAddresses[_admin] = true;
    }

     
     
    function removeAdmin(address _admin) external onlyOwner nonReentrant {
        _validateAddress(_admin);
         
        require(adminAddresses[_admin], "7");
        delete adminAddresses[_admin];
    }

     
     
    function addMarketDapp(address _dapp) external onlyOwner nonReentrant {
        _validateAddress(_dapp);
        marketDapps.push(_dapp);
    }

     
     
     
    function updateMarketDapp(uint256 _index, address _dapp) external onlyOwner nonReentrant {
        _validateAddress(_dapp);
         
        require(marketDapps[_index] != address(0), "8");
        marketDapps[_index] = _dapp;
    }

     
     
    function removeMarketDapp(uint256 _index) external onlyOwner nonReentrant {
         
        require(marketDapps[_index] != address(0), "9");
        delete marketDapps[_index];
    }

     
     
     
     
     
     
     
     
     
     
     
    function spendFrom(
        address _from,
        address _to,
        address _assetId,
        uint256 _amount
    )
        external
        nonReentrant
    {
        spenderList.validateSpenderAuthorization(_from, msg.sender);

        _validateAddress(_to);

        balances[_from][_assetId] = balances[_from][_assetId].sub(_amount);
        balances[_to][_assetId] = balances[_to][_assetId].add(_amount);
    }

     
     
     
     
     
     
     
     
    function markNonce(uint256 _nonce) external nonReentrant {
        spenderList.validateSpender(msg.sender);
        _markNonce(_nonce);
    }

     
     
     
    function nonceTaken(uint256 _nonce) external view returns (bool) {
        return _nonceTaken(_nonce);
    }

     
     
     
     
    function deposit() external payable onlyActiveState nonReentrant {
         
        require(msg.value > 0, "10");
        _increaseBalance(msg.sender, ETHER_ADDR, msg.value, REASON_DEPOSIT, 0);
    }

     
     
     
     
     
    function() payable external {}

     
     
     
     
     
     
     
     
     
     
     
     
     
    function depositToken(
        address _user,
        address _assetId,
        uint256 _amount,
        uint256 _expectedAmount,
        uint256 _nonce
    )
        external
        onlyAdmin
        onlyActiveState
        nonReentrant
    {
        _increaseBalance(
            _user,
            _assetId,
            _expectedAmount,
            REASON_DEPOSIT,
            _nonce
        );

        Utils.transferTokensIn(
            _user,
            _assetId,
            _amount,
            _expectedAmount
        );
    }

     
     
     
     
     
     
     
    function tokenFallback(
        address _user,
        uint _amount,
        bytes calldata  
    )
        external
        onlyActiveState
        nonReentrant
    {
        address assetId = msg.sender;
        tokenList.validateToken(assetId);
        _increaseBalance(_user, assetId, _amount, REASON_DEPOSIT, 0);
        emit TokenFallback(_user, assetId, _amount);
    }

     
     
     
     
     
     
     
     
    function tokensReceived(
        address  ,
        address _user,
        address _to,
        uint _amount,
        bytes calldata  ,
        bytes calldata  
    )
        external
        onlyActiveState
        nonReentrant
    {
        if (_to != address(this)) { return; }
        address assetId = msg.sender;
        tokenList.validateToken(assetId);
        _increaseBalance(_user, assetId, _amount, REASON_DEPOSIT, 0);
        emit TokensReceived(_user, assetId, _amount);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function trade(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses
    )
        public
        onlyAdmin
        onlyActiveState
        nonReentrant
    {
         
        address operatorAddress = operator;
         
        uint256[] memory statements;

         
        _cacheOfferNonceStates(_values);

         
         
         
        _hashes = Utils.validateTrades(
            _values,
            _hashes,
            _addresses,
            operatorAddress
        );

        statements = Utils.calculateTradeIncrements(_values, _addresses.length / 2);
        _incrementBalances(statements, _addresses, 1);

        statements = Utils.calculateTradeDecrements(_values, _addresses.length / 2);
        _decrementBalances(statements, _addresses);

         
         
         
        _storeOfferData(_values, _hashes);

         
        _storeFillNonces(_values);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function networkTrade(
        uint256[] memory _values,
        bytes32[] memory _hashes,
        address[] memory _addresses
    )
        public
        onlyAdmin
        onlyActiveState
        nonReentrant
    {
         
        address operatorAddress = operator;
         
        uint256[] memory statements;

         
        _cacheOfferNonceStates(_values);

         
         
         
         
        _hashes = Utils.validateNetworkTrades(
            _values,
            _hashes,
            _addresses,
            operatorAddress
        );

        statements = Utils.calculateNetworkTradeIncrements(_values, _addresses.length / 2);
        _incrementBalances(statements, _addresses, 1);

        statements = Utils.calculateNetworkTradeDecrements(_values, _addresses.length / 2);
        _decrementBalances(statements, _addresses);

         
         
         
        _storeOfferData(_values, _hashes);

         
         
        statements = Utils.performNetworkTrades(
            _values,
            _addresses,
            marketDapps
        );
        _incrementBalances(statements, _addresses, 0);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancel(
        uint256[] calldata _values,
        bytes32[] calldata _hashes,
        address[] calldata _addresses
    )
        external
        onlyAdmin
        nonReentrant
    {
        Utils.validateCancel(_values, _hashes, _addresses);
        bytes32 offerHash = Utils.hashOffer(_values, _addresses);
        _cancel(
            _addresses[0],  
            offerHash,
            _values[2] & mask128,  
            _addresses[1],  
            _values[2] >> 144,  
            _addresses[4],  
            _values[1] >> 128  
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function adminCancel(
        address _maker,
        address _offerAssetId,
        uint256 _offerAmount,
        address _wantAssetId,
        uint256 _wantAmount,
        address _feeAssetId,
        uint256 _feeAmount,
        uint256 _offerNonce,
        uint256 _expectedAvailableAmount
    )
        external
        onlyAdmin
        onlyEscalatedAdminState
        nonReentrant
    {
        bytes32 offerHash = keccak256(abi.encode(
            OFFER_TYPEHASH,
            _maker,
            _offerAssetId,
            _offerAmount,
            _wantAssetId,
            _wantAmount,
            _feeAssetId,
            _feeAmount,
            _offerNonce
        ));

        _cancel(
            _maker,
            offerHash,
            _expectedAvailableAmount,
            _offerAssetId,
            _offerNonce,
            address(0),
            0
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function announceCancel(
        address _maker,
        address _offerAssetId,
        uint256 _offerAmount,
        address _wantAssetId,
        uint256 _wantAmount,
        address _feeAssetId,
        uint256 _feeAmount,
        uint256 _offerNonce
    )
        external
        nonReentrant
    {
         
        require(_maker == msg.sender, "11");

        bytes32 offerHash = keccak256(abi.encode(
            OFFER_TYPEHASH,
            _maker,
            _offerAssetId,
            _offerAmount,
            _wantAssetId,
            _wantAmount,
            _feeAssetId,
            _feeAmount,
            _offerNonce
        ));

         
        require(offers[offerHash] > 0, "12");

        uint256 cancellableAt = now.add(slowCancelDelay);
        cancellationAnnouncements[offerHash] = cancellableAt;

        emit AnnounceCancel(offerHash, cancellableAt);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function slowCancel(
        address _maker,
        address _offerAssetId,
        uint256 _offerAmount,
        address _wantAssetId,
        uint256 _wantAmount,
        address _feeAssetId,
        uint256 _feeAmount,
        uint256 _offerNonce
    )
        external
        nonReentrant
    {
        bytes32 offerHash = keccak256(abi.encode(
            OFFER_TYPEHASH,
            _maker,
            _offerAssetId,
            _offerAmount,
            _wantAssetId,
            _wantAmount,
            _feeAssetId,
            _feeAmount,
            _offerNonce
        ));

        uint256 cancellableAt = cancellationAnnouncements[offerHash];
         
        require(cancellableAt != 0, "13");
         
        require(now >= cancellableAt, "14");

        uint256 availableAmount = offers[offerHash];
         
        require(availableAmount > 0, "15");

        delete cancellationAnnouncements[offerHash];
        _cancel(
            _maker,
            offerHash,
            availableAmount,
            _offerAssetId,
            _offerNonce,
            address(0),
            0
        );

        emit SlowCancel(offerHash, availableAmount);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function withdraw(
        address _withdrawer,
        address payable _receivingAddress,
        address _assetId,
        uint256 _amount,
        address _feeAssetId,
        uint256 _feeAmount,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bool _prefixedSignature
    )
        external
        onlyAdmin
        nonReentrant
    {
        _markNonce(_nonce);

        _validateSignature(
            keccak256(abi.encode(
                WITHDRAW_TYPEHASH,
                _withdrawer,
                _receivingAddress,
                _assetId,
                _amount,
                _feeAssetId,
                _feeAmount,
                _nonce
            )),
            _withdrawer,
            _v,
            _r,
            _s,
            _prefixedSignature
        );

        _withdraw(
            _withdrawer,
            _receivingAddress,
            _assetId,
            _amount,
            _feeAssetId,
            _feeAmount,
            _nonce
        );
    }

     
     
     
     
     
     
     
     
     
     
    function adminWithdraw(
        address payable _withdrawer,
        address _assetId,
        uint256 _amount,
        uint256 _nonce
    )
        external
        onlyAdmin
        onlyEscalatedAdminState
        nonReentrant
    {
        _markNonce(_nonce);

        _withdraw(
            _withdrawer,
            _withdrawer,
            _assetId,
            _amount,
            address(0),
            0,
            _nonce
        );
    }

     
     
     
     
     
     
     
    function announceWithdraw(
        address _assetId,
        uint256 _amount
    )
        external
        nonReentrant
    {

         
        require(_amount > 0 && _amount <= balances[msg.sender][_assetId], "16");

        WithdrawalAnnouncement storage announcement = withdrawalAnnouncements[msg.sender][_assetId];

        announcement.withdrawableAt = now.add(slowWithdrawDelay);
        announcement.amount = _amount;

        emit AnnounceWithdraw(msg.sender, _assetId, _amount, announcement.withdrawableAt);
    }

     
     
     
     
     
     
     
    function slowWithdraw(
        address payable _withdrawer,
        address _assetId,
        uint256 _amount
    )
        external
        nonReentrant
    {
        WithdrawalAnnouncement memory announcement = withdrawalAnnouncements[_withdrawer][_assetId];

         
        require(announcement.withdrawableAt != 0, "17");
         
        require(now >= announcement.withdrawableAt, "18");
         
        require(announcement.amount == _amount, "19");

        delete withdrawalAnnouncements[_withdrawer][_assetId];
        _withdraw(
            _withdrawer,
            _withdrawer,
            _assetId,
            _amount,
            address(0),
            0,
            0
        );
        emit SlowWithdraw(_withdrawer, _assetId, _amount);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function createSwap(
        address[4] calldata _addresses,
        uint256[4] calldata _values,
        bytes32[3] calldata _hashes,
        uint8 _v,
        bool _prefixedSignature
    )
        external
        onlyAdmin
        onlyActiveState
        nonReentrant
    {
         
        require(_values[0] > 0, "20");
         
        require(_values[1] > now, "21");
        _validateAddress(_addresses[1]);

         
        require(_addresses[0] != _addresses[1], "39");

        bytes32 swapHash = _hashSwap(_addresses, _values, _hashes[0]);
         
        require(!atomicSwaps[swapHash], "22");

        _markNonce(_values[3]);

        _validateSignature(
            swapHash,
            _addresses[0],  
            _v,
            _hashes[1],  
            _hashes[2],  
            _prefixedSignature
        );

        if (_addresses[3] == _addresses[2]) {  
             
            require(_values[2] < _values[0], "23");  
        } else {
            _decreaseBalance(
                _addresses[0],  
                _addresses[3],  
                _values[2],  
                REASON_SWAP_FEE_GIVE,
                _values[3]  
            );
        }

        _decreaseBalance(
            _addresses[0],  
            _addresses[2],  
            _values[0],  
            REASON_SWAP_GIVE,
            _values[3]  
        );

        atomicSwaps[swapHash] = true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function executeSwap(
        address[4] calldata _addresses,
        uint256[4] calldata _values,
        bytes32 _hashedSecret,
        bytes calldata _preimage
    )
        external
        nonReentrant
    {
         
        require(_preimage.length <= MAX_SWAP_SECRET_LENGTH, "37");

        bytes32 swapHash = _hashSwap(_addresses, _values, _hashedSecret);
         
        require(atomicSwaps[swapHash], "24");
         
        require(sha256(abi.encodePacked(sha256(_preimage))) == _hashedSecret, "25");

        uint256 takeAmount = _values[0];
        if (_addresses[3] == _addresses[2]) {  
            takeAmount = takeAmount.sub(_values[2]);
        }

        delete atomicSwaps[swapHash];

        _increaseBalance(
            _addresses[1],  
            _addresses[2],  
            takeAmount,
            REASON_SWAP_RECEIVE,
            _values[3]  
        );

        _increaseBalance(
            operator,
            _addresses[3],  
            _values[2],  
            REASON_SWAP_FEE_RECEIVE,
            _values[3]  
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelSwap(
        address[4] calldata _addresses,
        uint256[4] calldata _values,
        bytes32 _hashedSecret,
        uint256 _cancelFeeAmount
    )
        external
        nonReentrant
    {
         
        require(_values[1] <= now, "26");
        bytes32 swapHash = _hashSwap(_addresses, _values, _hashedSecret);
         
        require(atomicSwaps[swapHash], "27");

        uint256 cancelFeeAmount = _cancelFeeAmount;
        if (!adminAddresses[msg.sender]) { cancelFeeAmount = _values[2]; }

         
         
        require(cancelFeeAmount <= _values[2], "28");

        uint256 refundAmount = _values[0];
        if (_addresses[3] == _addresses[2]) {  
            refundAmount = refundAmount.sub(cancelFeeAmount);
        }

        delete atomicSwaps[swapHash];

        _increaseBalance(
            _addresses[0],  
            _addresses[2],  
            refundAmount,
            REASON_SWAP_CANCEL_RECEIVE,
            _values[3]  
        );

        _increaseBalance(
            operator,
            _addresses[3],  
            cancelFeeAmount,
            REASON_SWAP_CANCEL_FEE_RECEIVE,
            _values[3]  
        );

        if (_addresses[3] != _addresses[2]) {  
            uint256 refundFeeAmount = _values[2].sub(cancelFeeAmount);
            _increaseBalance(
                _addresses[0],  
                _addresses[3],  
                refundFeeAmount,
                REASON_SWAP_CANCEL_FEE_REFUND,
                _values[3]  
            );
        }
    }

     
     
    function _cacheOfferNonceStates(uint256[] memory _values) private view {
        uint256 i = 1;
         
        uint256 end = i + (_values[0] & mask8) * 2;

         
        for(i; i < end; i += 2) {
             
            require(((_values[i] & mask128) >> 120) == 0, "38");

            uint256 nonce = (_values[i] & mask120) >> 56;
            if (_nonceTaken(nonce)) {
                _values[i] = _values[i] | (uint256(1) << 120);
            }
        }
    }

     
     
     
     
     
     
    function _storeOfferData(
        uint256[] memory _values,
        bytes32[] memory _hashes
    )
        private
    {
         
        uint256[] memory takenAmounts = new uint256[](_values[0] & mask8);

        uint256 i = 1;
         
        i += (_values[0] & mask8) * 2;
         
        i += ((_values[0] & mask16) >> 8) * 2;

        uint256 end = _values.length;

         
        for (i; i < end; i++) {
            uint256 offerIndex = _values[i] & mask8;
            uint256 takeAmount = _values[i] >> 128;
            takenAmounts[offerIndex] = takenAmounts[offerIndex].add(takeAmount);
        }

        i = 0;
        end = _values[0] & mask8;  

         
        for (i; i < end; i++) {
             
             
            bool existingOffer = ((_values[i * 2 + 1] & mask128) >> 120) == 1;
            bytes32 hashKey = _hashes[i * 2];

            uint256 availableAmount = existingOffer ? offers[hashKey] : (_values[i * 2 + 2] & mask128);
             
            require(availableAmount > 0, "31");

            uint256 remainingAmount = availableAmount.sub(takenAmounts[i]);
            if (remainingAmount > 0) { offers[hashKey] = remainingAmount; }
            if (existingOffer && remainingAmount == 0) { delete offers[hashKey]; }

            if (!existingOffer) {
                uint256 nonce = (_values[i * 2 + 1] & mask120) >> 56;
                _markNonce(nonce);
            }
        }
    }

     
     
     
     
     
     
    function _storeFillNonces(uint256[] memory _values) private {
         
        uint256 i = 1 + (_values[0] & mask8) * 2;
         
        uint256 end = i + ((_values[0] & mask16) >> 8) * 2;

         
        for(i; i < end; i += 2) {
            uint256 nonce = (_values[i] & mask120) >> 56;
            _markNonce(nonce);
        }
    }

     
     
     
     
    function _cancel(
        address _maker,
        bytes32 _offerHash,
        uint256 _expectedAvailableAmount,
        address _offerAssetId,
        uint256 _offerNonce,
        address _cancelFeeAssetId,
        uint256 _cancelFeeAmount
    )
        private
    {
        uint256 refundAmount = offers[_offerHash];
         
        require(refundAmount > 0, "32");
         
         
        require(refundAmount == _expectedAvailableAmount, "33");

        delete offers[_offerHash];

        if (_cancelFeeAssetId == _offerAssetId) {
            refundAmount = refundAmount.sub(_cancelFeeAmount);
        } else {
            _decreaseBalance(
                _maker,
                _cancelFeeAssetId,
                _cancelFeeAmount,
                REASON_CANCEL_FEE_GIVE,
                _offerNonce
            );
        }

        _increaseBalance(
            _maker,
            _offerAssetId,
            refundAmount,
            REASON_CANCEL,
            _offerNonce
        );

        _increaseBalance(
            operator,
            _cancelFeeAssetId,
            _cancelFeeAmount,
            REASON_CANCEL_FEE_RECEIVE,
            _offerNonce  
        );
    }

     
     
     
     
     
    function _withdraw(
        address _withdrawer,
        address payable _receivingAddress,
        address _assetId,
        uint256 _amount,
        address _feeAssetId,
        uint256 _feeAmount,
        uint256 _nonce
    )
        private
    {
         
        require(_amount > 0, "34");

        _validateAddress(_receivingAddress);

        _decreaseBalance(
            _withdrawer,
            _assetId,
            _amount,
            REASON_WITHDRAW,
            _nonce
        );

        _increaseBalance(
            operator,
            _feeAssetId,
            _feeAmount,
            REASON_WITHDRAW_FEE_RECEIVE,
            _nonce
        );

        uint256 withdrawAmount;

        if (_feeAssetId == _assetId) {
            withdrawAmount = _amount.sub(_feeAmount);
        } else {
            _decreaseBalance(
                _withdrawer,
                _feeAssetId,
                _feeAmount,
                REASON_WITHDRAW_FEE_GIVE,
                _nonce
            );
            withdrawAmount = _amount;
        }

        if (_assetId == ETHER_ADDR) {
            _receivingAddress.transfer(withdrawAmount);
            return;
        }

        Utils.transferTokensOut(
            _receivingAddress,
            _assetId,
            withdrawAmount
        );
    }

     
     
     
     
     
     
     
     
     
     
     
    function _hashSwap(
        address[4] memory _addresses,
        uint256[4] memory _values,
        bytes32 _hashedSecret
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            SWAP_TYPEHASH,
            _addresses[0],  
            _addresses[1],  
            _addresses[2],  
            _values[0],  
            _hashedSecret,  
            _values[1],  
            _addresses[3],  
            _values[2],  
            _values[3]  
        ));
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function _nonceTaken(uint256 _nonce) private view returns (bool) {
        uint256 slotData = _nonce.div(256);
        uint256 shiftedBit = uint256(1) << _nonce.mod(256);
        uint256 bits = usedNonces[slotData];

         
         
         
        return bits & shiftedBit != 0;
    }

     
     
     
     
     
    function _markNonce(uint256 _nonce) private {
         
        require(_nonce != 0, "35");

        uint256 slotData = _nonce.div(256);
        uint256 shiftedBit = 1 << _nonce.mod(256);
        uint256 bits = usedNonces[slotData];

         
        require(bits & shiftedBit == 0, "36");

        usedNonces[slotData] = bits | shiftedBit;
    }

     
     
     
     
     
     
     
     
     
     
     
    function _validateSignature(
        bytes32 _hash,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bool _prefixed
    )
        private
        pure
    {
        Utils.validateSignature(
            _hash,
            _user,
            _v,
            _r,
            _s,
            _prefixed
        );
    }

     
     
     
     
     
     
     
    function _increaseBalance(
        address _user,
        address _assetId,
        uint256 _amount,
        uint256 _reasonCode,
        uint256 _nonce
    )
        private
    {
        if (_amount == 0) { return; }
        balances[_user][_assetId] = balances[_user][_assetId].add(_amount);

        emit BalanceIncrease(
            _user,
            _assetId,
            _amount,
            _reasonCode,
            _nonce
        );
    }

     
     
     
     
     
     
     
    function _decreaseBalance(
        address _user,
        address _assetId,
        uint256 _amount,
        uint256 _reasonCode,
        uint256 _nonce
    )
        private
    {
        if (_amount == 0) { return; }
        balances[_user][_assetId] = balances[_user][_assetId].sub(_amount);

        emit BalanceDecrease(
            _user,
            _assetId,
            _amount,
            _reasonCode,
            _nonce
        );
    }

     
     
    function _validateAddress(address _address) private pure {
        Utils.validateAddress(_address);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _incrementBalances(
        uint256[] memory _increments,
        address[] memory _addresses,
        uint256 _static
    )
        private
    {
        uint256 end = _increments.length;

        for(uint256 i = 0; i < end; i++) {
            uint256 increment = _increments[i];
            if (increment == 0) { continue; }

            balances[_addresses[i * 2]][_addresses[i * 2 + 1]] =
            balances[_addresses[i * 2]][_addresses[i * 2 + 1]].add(increment);

            emit Increment((i << 248) | (_static << 240) | increment);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function _decrementBalances(
        uint256[] memory _decrements,
        address[] memory _addresses
    )
        private
    {
        uint256 end = _decrements.length;
        for(uint256 i = 0; i < end; i++) {
            uint256 decrement = _decrements[i];
            if (decrement == 0) { continue; }

            balances[_addresses[i * 2]][_addresses[i * 2 + 1]] =
            balances[_addresses[i * 2]][_addresses[i * 2 + 1]].sub(decrement);

            emit Decrement(i << 248 | decrement);
        }
    }
}