 

pragma solidity ^0.4.23;

contract Htlc {

     

    enum State { Created, Refunded, Redeemed }

     

    struct Channel {  
        address initiator;  
        address beneficiary;  
        uint amount;  
        uint commission;  
        uint createdAt;  
        uint expiresAt;  
        bytes32 hashedSecret;  
        State state;  
    }

     

    uint constant MAX_BATCH_ITERATIONS = 20;  
    mapping (bytes32 => Channel) public channels;  
    mapping (bytes32 => bool) public isAntecedentHashedSecret;  
    address public EXCHANGE_OPERATOR;  
    bool public IS_EXCHANGE_OPERATIONAL;  
    address public COMMISSION_RECIPIENT;  

     

    event ChannelCreated(bytes32 channelId);
    event ChannelRedeemed(bytes32 channelId);
    event ChannelRefunded(bytes32 channelId);

     

    modifier only_exchange_operator {
        require(msg.sender == EXCHANGE_OPERATOR, "PERMISSION_DENIED");
        _;
    }

     

     

     
    function _setupChannel(address beneficiary, uint amount, uint commission, uint expiresAt, bytes32 hashedSecret)
        private
        returns (bytes32 channelId)
    {
        require(IS_EXCHANGE_OPERATIONAL, "EXCHANGE_NOT_OPERATIONAL");
        require(now <= expiresAt, "TIMELOCK_TOO_EARLY");
        require(amount > 0, "AMOUNT_IS_ZERO");
        require(!isAntecedentHashedSecret[hashedSecret], "SECRET_CAN_BE_DISCOVERED");
        isAntecedentHashedSecret[hashedSecret] = true;
         
        channelId = createChannelId(
            msg.sender,
            beneficiary,
            amount,
            commission,
            now,
            expiresAt,
            hashedSecret
        );
         
        Channel storage channel = channels[channelId];
        channel.initiator = msg.sender;
        channel.beneficiary = beneficiary;
        channel.amount = amount;
        channel.commission = commission;
        channel.createdAt = now;
        channel.expiresAt = expiresAt;
        channel.hashedSecret = hashedSecret;
        channel.state = State.Created;
         
        COMMISSION_RECIPIENT.transfer(commission);
        emit ChannelCreated(channelId);
    }

     

     
    function Htlc(
        address ofExchangeOperator,
        address ofCommissionRecipient
    )
        public
    {
        EXCHANGE_OPERATOR = ofExchangeOperator;
        IS_EXCHANGE_OPERATIONAL = true;
        COMMISSION_RECIPIENT = ofCommissionRecipient;
    }

     
    function changeExchangeOperator(address newExchangeOperator)
        public
        only_exchange_operator
    {
        EXCHANGE_OPERATOR = newExchangeOperator;
    }

     
    function changeExchangeStatus(bool newExchangeState)
        public
        only_exchange_operator
    {
        IS_EXCHANGE_OPERATIONAL = newExchangeState;
    }

     
    function changeCommissionRecipient(address newCommissionRecipient)
        public
        only_exchange_operator
    {
        COMMISSION_RECIPIENT = newCommissionRecipient;
    }

     
    function createChannelId(
        address initiator,
        address beneficiary,
        uint amount,
        uint commission,
        uint createdAt,
        uint expiresAt,
        bytes32 hashedSecret
    )
        public
        pure
        returns (bytes32 channelId)
    {
        channelId = keccak256(abi.encodePacked(
            initiator,
            beneficiary,
            amount,
            commission,
            createdAt,
            expiresAt,
            hashedSecret
        ));
    }

     
    function createChannel(
        address beneficiary,
        uint amount,
        uint commission,
        uint expiresAt,
        bytes32 hashedSecret
    )
        public
        payable
        returns (bytes32 channelId)
    {
         
        require(amount + commission >= amount, "UINT256_OVERFLOW");
        require(msg.value == amount + commission, "INACCURATE_MSG_VALUE_SENT");
         
        _setupChannel(
            beneficiary,
            amount,
            commission,
            expiresAt,
            hashedSecret
        );
    }

     
    function batchCreateChannel(
        address[] beneficiaries,
        uint[] amounts,
        uint[] commissions,
        uint[] expiresAts,
        bytes32[] hashedSecrets
    )
        public
        payable
        returns (bytes32[] channelId)
    {
        require(beneficiaries.length <= MAX_BATCH_ITERATIONS, "TOO_MANY_CHANNELS");
         
        uint valueToBeSent;
        for (uint i = 0; i < beneficiaries.length; ++i) {
            require(amounts[i] + commissions[i] >= amounts[i], "UINT256_OVERFLOW");
            require(valueToBeSent + amounts[i] + commissions[i] >= valueToBeSent, "UINT256_OVERFLOW");
            valueToBeSent += amounts[i] + commissions[i];
        }
        require(msg.value == valueToBeSent, "INACCURATE_MSG_VALUE_SENT");
         
        for (i = 0; i < beneficiaries.length; ++i)
            _setupChannel(
                beneficiaries[i],
                amounts[i],
                commissions[i],
                expiresAts[i],
                hashedSecrets[i]
            );
    }

     
    function redeemChannel(bytes32 channelId, bytes32 secret)
        public
    {
         
        require(sha256(abi.encodePacked(secret)) == channels[channelId].hashedSecret, "WRONG_SECRET");
        require(channels[channelId].state == State.Created, "WRONG_STATE");
        uint amount = channels[channelId].amount;
        address beneficiary = channels[channelId].beneficiary;
        channels[channelId].state = State.Redeemed;
         
        beneficiary.transfer(amount);
        emit ChannelRedeemed(channelId);
    }

     
    function batchRedeemChannel(bytes32[] channelIds, bytes32[] secrets)
        public
    {
        require(channelIds.length <= MAX_BATCH_ITERATIONS, "TOO_MANY_CHANNELS");
        for (uint i = 0; i < channelIds.length; ++i)
            redeemChannel(channelIds[i], secrets[i]);
    }

     
    function refundChannel(bytes32 channelId)
        public
    {
         
        require(now >= channels[channelId].expiresAt, "TOO_EARLY");
        require(channels[channelId].state == State.Created, "WRONG_STATE");
        uint amount = channels[channelId].amount;
        address initiator = channels[channelId].initiator;
        channels[channelId].state = State.Refunded;
         
        initiator.transfer(amount);
        emit ChannelRefunded(channelId);
    }

     
    function batchRefundChannel(bytes32[] channelIds)
        public
    {
        require(channelIds.length <= MAX_BATCH_ITERATIONS, "TOO_MANY_CHANNELS");
        for (uint i = 0; i < channelIds.length; ++i)
            refundChannel(channelIds[i]);
    }
}