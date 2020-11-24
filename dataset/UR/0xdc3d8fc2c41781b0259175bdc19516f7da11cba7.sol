 

pragma solidity ^0.5.7;

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
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

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FizzyRoles is Ownable {
    address private _signer;
    address payable private _assetManager;
    address private _oracle;

    event SignershipTransferred(address previousSigner, address newSigner);
    event AssetManagerChanged(address payable previousAssetManager, address payable newAssetManager);
    event OracleChanged(address previousOracle, address newOracle);

     
    modifier onlyAssetManager() {
        require(_assetManager == msg.sender, "Sender is not the asset manager");
        _;
    }

     
    modifier onlyOracle() {
        require(_oracle == msg.sender, "Sender is not the oracle");
        _;
    }

     
    constructor () internal {
        _signer = msg.sender;
        _assetManager = msg.sender;
        _oracle = msg.sender;
        emit SignershipTransferred(address(0), _signer);
        emit AssetManagerChanged(address(0), _assetManager);
        emit OracleChanged(address(0), _oracle);
    }

     
    function transferSignership(address newSigner) external onlyOwner {
        require(newSigner != address(0), "newSigner should not be address(0).");
        emit SignershipTransferred(_signer, newSigner);
        _signer = newSigner;
    }

     
    function changeAssetManager(address payable newManager) external onlyOwner {
        require(newManager != address(0), "newManager should not be address(0).");
        emit AssetManagerChanged(_assetManager, newManager);
        _assetManager = newManager;
    }

     
    function changeOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "newOracle should not be address(0).");
        emit OracleChanged(_oracle, newOracle);
        _oracle = newOracle;
    }

     
    function getSigner() public view returns(address) {
        return _signer;
    }

     
    function getOracle() public view returns(address) {
        return _oracle;
    }

     
    function getAssetManager() public view returns(address payable) {
        return _assetManager;
    }
}

contract Fizzy is FizzyRoles {

     
    uint256 constant NONE       = 0;
    uint256 constant CANCELLED  = 2**0;
    uint256 constant DIVERTED   = 2**1;
    uint256 constant REDIRECTED = 2**2;
    uint256 constant DELAY      = 2**3;
    uint256 constant MANUAL     = 2**4;

     
    enum InsuranceStatus {
        Open, ClosedCompensated, ClosedNotCompensated
    }

     
    struct Insurance {
        uint256         productId;
        uint256         premium;
        uint256         indemnity;
        uint256         limitArrivalTime;
        uint256         conditions;
        InsuranceStatus status;
        address payable compensationAddress;
    }

     
    mapping(bytes32 => Insurance[]) private insuranceList;

     
    mapping(uint256 => bool) private boughtProductIds;

     

    event InsuranceCreation(
        bytes32         flightId,
        uint256         productId,
        uint256         premium,
        uint256         indemnity,
        uint256         limitArrivalTime,
        uint256         conditions,
        address payable compensationAddress
    );

     
    event InsuranceUpdate(
        bytes32         flightId,
        uint256         productId,
        uint256         premium,
        uint256         indemnity,
        uint256         triggeredCondition,
        InsuranceStatus status
    );

     
    function getInsurancesCount(bytes32 flightId) public view returns (uint256) {
        return insuranceList[flightId].length;
    }

     
    function getInsurance(bytes32 flightId, uint256 index) public view returns (uint256         productId,
                                                                uint256         premium,
                                                                uint256         indemnity,
                                                                uint256         limitArrivalTime,
                                                                uint256         conditions,
                                                                InsuranceStatus status,
                                                                address payable compensationAddress) {
        productId = insuranceList[flightId][index].productId;
        premium = insuranceList[flightId][index].premium;
        indemnity = insuranceList[flightId][index].indemnity;
        limitArrivalTime = insuranceList[flightId][index].limitArrivalTime;
        conditions = insuranceList[flightId][index].conditions;
        status = insuranceList[flightId][index].status;
        compensationAddress = insuranceList[flightId][index].compensationAddress;
    }


     
    function isProductBought(uint256 productId) public view returns (bool) {
        return boughtProductIds[productId];
    }

     
    function addNewInsurance(
        bytes32 flightId,
        uint256 productId,
        uint256 premium,
        uint256 indemnity,
        uint256 limitArrivalTime,
        uint256 conditions
        ) external onlyOwner {

        _addNewInsurance(flightId, productId, premium, indemnity, limitArrivalTime, conditions, address(0));
    }

     
    function setFlightLandedAndArrivalTime(
        bytes32 flightId,
        uint256 actualArrivalTime)
        external
        onlyOracle {

        for (uint i = 0; i < insuranceList[flightId].length; i++) {
            Insurance memory insurance = insuranceList[flightId][i];
            if (insurance.status == InsuranceStatus.Open) {
                InsuranceStatus newStatus;
                uint256 triggeredCondition;

                if (_containsCondition(insurance.conditions, DELAY)) {
                    if (actualArrivalTime > insurance.limitArrivalTime) {
                        triggeredCondition = DELAY;
                        newStatus = InsuranceStatus.ClosedCompensated;
                        compensateIfEtherPayment(insurance);
                    } else {
                        triggeredCondition = NONE;
                        newStatus = InsuranceStatus.ClosedNotCompensated;
                        noCompensateIfEtherPayment(insurance);
                    }
                } else {
                    triggeredCondition = NONE;
                    newStatus = InsuranceStatus.ClosedNotCompensated;
                    noCompensateIfEtherPayment(insurance);
                }

                insuranceList[flightId][i].status = newStatus;

                emit InsuranceUpdate(
                    flightId,
                    insurance.productId,
                    insurance.premium,
                    insurance.indemnity,
                    triggeredCondition,
                    newStatus
                    );
            }
        }
    }

     
    function triggerCondition(
        bytes32 flightId,
        uint256 conditionToTrigger)
        external
        onlyOracle {

        for (uint i = 0; i < insuranceList[flightId].length; i++) {
            Insurance memory insurance = insuranceList[flightId][i];

            if (insurance.status == InsuranceStatus.Open) {
                InsuranceStatus newInsuranceStatus;
                uint256 triggeredCondition;

                if (_containsCondition(insurance.conditions, conditionToTrigger)) {
                    triggeredCondition = conditionToTrigger;
                    newInsuranceStatus = InsuranceStatus.ClosedCompensated;
                    compensateIfEtherPayment(insurance);
                } else {
                    triggeredCondition = NONE;
                    newInsuranceStatus = InsuranceStatus.ClosedNotCompensated;
                    noCompensateIfEtherPayment(insurance);
                }

                insuranceList[flightId][i].status = newInsuranceStatus;

                emit InsuranceUpdate(
                    flightId,
                    insurance.productId,
                    insurance.premium,
                    insurance.indemnity,
                    triggeredCondition,
                    newInsuranceStatus
                    );
            }
        }
    }

     
    function manualInsuranceResolution(
        bytes32 flightId,
        uint256 productId,
        InsuranceStatus newStatus
    )
        external
        onlyOwner {
        require(newStatus == InsuranceStatus.ClosedCompensated || newStatus == InsuranceStatus.ClosedNotCompensated,
                "Insurance already compensated.");

        for (uint i = 0; i < insuranceList[flightId].length; i++) {
            Insurance memory insurance = insuranceList[flightId][i];
            if (insurance.status == InsuranceStatus.Open && insurance.productId == productId) {
                if (newStatus == InsuranceStatus.ClosedCompensated) {
                    compensateIfEtherPayment(insurance);
                } else if (newStatus == InsuranceStatus.ClosedNotCompensated) {
                    noCompensateIfEtherPayment(insurance);
                }

                insuranceList[flightId][i].status = newStatus;

                emit InsuranceUpdate(
                    flightId,
                    insurance.productId,
                    insurance.premium,
                    insurance.indemnity,
                    MANUAL,
                    newStatus
                    );
            }
        }
    }

    function _addNewInsurance (
        bytes32 flightId,
        uint256 productId,
        uint256 premium,
        uint256 indemnity,
        uint256  limitArrivalTime,
        uint256 conditions,
        address payable compensationAddress
    ) internal {

        require(boughtProductIds[productId] == false, "This product has already been bought.");

        Insurance memory newInsurance;
        newInsurance.productId = productId;
        newInsurance.premium = premium;
        newInsurance.indemnity = indemnity;
        newInsurance.limitArrivalTime = limitArrivalTime;
        newInsurance.conditions = conditions;
        newInsurance.status = InsuranceStatus.Open;
        newInsurance.compensationAddress = compensationAddress;

        insuranceList[flightId].push(newInsurance);

        boughtProductIds[productId] = true;

        emit InsuranceCreation(flightId, productId, premium, indemnity, limitArrivalTime, conditions, compensationAddress);
    }

    function _compensate(address payable to, uint256 amount, uint256 productId) internal returns (bool success);
    function _noCompensate(uint256 amount) internal returns (bool success);

     
    function compensateIfEtherPayment(Insurance memory insurance) private {
        if (insurance.compensationAddress != address(0)) {
            _compensate(insurance.compensationAddress, insurance.indemnity, insurance.productId);
        }
    }

     
    function noCompensateIfEtherPayment(Insurance memory insurance) private {
        if (insurance.compensationAddress != address(0)) {
            _noCompensate(insurance.indemnity);
        }
    }

     
    function _containsCondition(uint256 a, uint256 b) private pure returns (bool) {
        return (a & b) != 0;
    }
}

contract FizzyCrypto is Fizzy {

    uint256 private _availableExposure;
    uint256 private _collectedTaxes;

    event EtherCompensation(uint256 amount, address to, uint256 productId);
    event EtherCompensationError(uint256 amount, address to, uint256 productId);

     
    modifier beforeTimestampLimit(uint256 timestampLimit) {
        require(timestampLimit >= now, "The transaction is invalid: the timestamp limit has been reached.");
        _;
    }

     
    modifier enoughExposure(uint256 amount) {
        require(_availableExposure >= amount, "Available exposure can not be reached");
        _;
    }

     
    modifier enoughTaxes(uint256 amount) {
        require(_collectedTaxes >= amount, "Cannot withdraw more taxes than all collected taxes");
        _;
    }

     
    function deposit() external payable onlyAssetManager {
        _availableExposure = _availableExposure + msg.value;
    }

     
    function withdraw(uint256 amount) external onlyAssetManager enoughExposure(amount) {
        _availableExposure = _availableExposure - amount;
        msg.sender.transfer(amount);
    }

     
    function withdrawTaxes(uint256 amount) external onlyAssetManager enoughTaxes(amount) {
        _collectedTaxes = _collectedTaxes - amount;
        msg.sender.transfer(amount);
    }

     
    function buyInsurance(
        bytes32        flightId,
        uint256        productId,
        uint256        premium,
        uint256        indemnity,
        uint256        taxes,
        uint256        limitArrivalTime,
        uint256        conditions,
        uint256        timestampLimit,
        address        buyerAddress,
        bytes calldata signature
    )
        external
        payable
        beforeTimestampLimit(timestampLimit)
        enoughExposure(indemnity)
    {
        _checkSignature(flightId, productId, premium, indemnity, taxes, limitArrivalTime, conditions, timestampLimit, buyerAddress, signature);

        require(buyerAddress == msg.sender, "Wrong buyer address.");
        require(premium >= taxes, "The taxes must be included in the premium.");
        require(premium == msg.value, "The amount sent does not match the price of the order.");

        _addNewInsurance(flightId, productId, premium, indemnity, limitArrivalTime, conditions, msg.sender);

        _availableExposure = _availableExposure + premium - taxes - indemnity;
        _collectedTaxes = _collectedTaxes + taxes;
    }

     
    function availableExposure() external view returns(uint256) {
        return _availableExposure;
    }

     
    function collectedTaxes() external view returns(uint256) {
        return _collectedTaxes;
    }

     
    function _compensate(address payable to, uint256 amount, uint256 productId) internal returns (bool) {
        if(to.send(amount)) {
            emit EtherCompensation(amount, to, productId);
            return true;
        } else {
            getAssetManager().transfer(amount);
            emit EtherCompensationError(amount, to, productId);
            return false;
        }
    }

     
    function _noCompensate(uint256 amount) internal returns (bool) {
        _availableExposure = _availableExposure + amount;
        return true;
    }

     
    function _checkSignature(
        bytes32 flightId,
        uint256 productId,
        uint256 premium,
        uint256 indemnity,
        uint256 taxes,
        uint256 limitArrivalTime,
        uint256 conditions,
        uint256 timestampLimit,
        address buyerAddress,
        bytes memory signature
    ) private view {

        bytes32 messageHash = keccak256(abi.encodePacked(
            flightId,
            productId,
            premium,
            indemnity,
            taxes,
            limitArrivalTime,
            conditions,
            timestampLimit,
            buyerAddress
        ));

        address decypheredAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);
        require(decypheredAddress == getSigner(), "The signature is invalid if it does not match the _signer address.");
    }
}