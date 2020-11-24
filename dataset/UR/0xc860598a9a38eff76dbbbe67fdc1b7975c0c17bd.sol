 

 

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


interface Broker {
    function owner() external returns (address);
    function isAdmin(address _user) external returns(bool);
    function markNonce(uint256 _nonce) external;
}

contract BrokerExtension is ReentrancyGuard {
    Broker public broker;

    modifier onlyAdmin() {
        require(broker.isAdmin(msg.sender), "Invalid msg.sender");
        _;
    }

    modifier onlyOwner() {
        require(broker.owner() == msg.sender, "Invalid msg.sender");
        _;
    }

    function initializeBroker(address _brokerAddress) external {
        require(_brokerAddress != address(0), "Invalid _brokerAddress");
        require(address(broker) == address(0), "Broker already set");
        broker = Broker(_brokerAddress);
    }
}

 

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


interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface MarketDapp {
     
    function tokenReceiver(address[] calldata assetIds, uint256[] calldata dataValues, address[] calldata addresses) external view returns(address);
    function trade(address[] calldata assetIds, uint256[] calldata dataValues, address[] calldata addresses, address payable recipient) external payable;
}

 
 
 
 
 
library Utils {
    using SafeMath for uint256;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
    bytes32 public constant DOMAIN_SEPARATOR = 0x14f697e312cdba1c10a1eb5c87d96fa22b63aef9dc39592568387471319ea630;

     
     
     
     
     
     
     
     
     
     
     
     
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
                _addresses[(_values[1 + offerIndex * 2] & mask8) * 2] !=
                _addresses[(_values[1 + fillIndex * 2] & mask8) * 2],
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

            uint256 operatorFeeAssetIndex = ((dataA & mask40) >> 32) * 2;

             require(
                _addresses[operatorFeeAssetIndex] == _operator,
                "Invalid operator address"
            );

             require(
                _addresses[operatorFeeAssetIndex + 1] ==
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



 
 
 
 
 
contract TokenList is BrokerExtension {
     
     
     
    mapping(address => bool) public tokenWhitelist;

     
     
     
     
     
     
    function whitelistToken(address _assetId) external onlyOwner nonReentrant {
        Utils.validateAddress(_assetId);
        require(!tokenWhitelist[_assetId], "Token already whitelisted");
        tokenWhitelist[_assetId] = true;
    }

     
     
    function unwhitelistToken(address _assetId) external onlyOwner nonReentrant {
        Utils.validateAddress(_assetId);
        require(tokenWhitelist[_assetId], "Token not whitelisted");
        delete tokenWhitelist[_assetId];
    }

     
     
    function validateToken(address _assetId) external view {
        require(tokenWhitelist[_assetId], "Invalid token");
    }
}