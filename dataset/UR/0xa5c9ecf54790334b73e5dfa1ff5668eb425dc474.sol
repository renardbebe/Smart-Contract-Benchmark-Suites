 

pragma solidity ^0.4.23;

 
 
 
contract Utils {
    string constant public contract_version = "0.4.0";

     
     
     
     
    function contractExists(address contract_address) public view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
}


interface Token {

     
    function totalSupply() external view returns (uint256 supply);

     
     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function decimals() external view returns (uint8 decimals);
}


library ECVerify {

    function ecverify(bytes32 hash, bytes signature)
        internal
        pure
        returns (address signature_address)
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))

             
            v := byte(0, mload(add(signature, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        signature_address = ecrecover(hash, v, r, s);

         
        require(signature_address != address(0x0));

        return signature_address;
    }
}


 
 
 
contract SecretRegistry {

    string constant public contract_version = "0.4.0";

     
    mapping(bytes32 => uint256) private secrethash_to_block;

    event SecretRevealed(bytes32 indexed secrethash, bytes32 secret);

     
     
     
     
     
    function registerSecret(bytes32 secret) public returns (bool) {
        bytes32 secrethash = keccak256(abi.encodePacked(secret));
        if (secret == bytes32(0x0) || secrethash_to_block[secrethash] > 0) {
            return false;
        }
        secrethash_to_block[secrethash] = block.number;
        emit SecretRevealed(secrethash, secret);
        return true;
    }

     
     
     
     
    function registerSecretBatch(bytes32[] secrets) public returns (bool) {
        bool completeSuccess = true;
        for(uint i = 0; i < secrets.length; i++) {
            if(!registerSecret(secrets[i])) {
                completeSuccess = false;
            }
        }
        return completeSuccess;
    }

     
     
     
    function getSecretRevealBlockHeight(bytes32 secrethash) public view returns (uint256) {
        return secrethash_to_block[secrethash];
    }
}



 
 
 
 
contract TokenNetwork is Utils {

    string constant public contract_version = "0.4.0";

     
    Token public token;

     
     
    SecretRegistry public secret_registry;

     
     
    uint256 public chain_id;

    uint256 public settlement_timeout_min;
    uint256 public settlement_timeout_max;

    uint256 constant public MAX_SAFE_UINT256 = (
        115792089237316195423570985008687907853269984665640564039457584007913129639935
    );

     
     
     
    uint256 constant public channel_participant_deposit_limit = 75000000000000000 wei;
     
     
    uint256 constant public token_network_deposit_limit = 250000000000000000000 wei;

     
     
    uint256 public channel_counter;

    string public constant signature_prefix = '\x19Ethereum Signed Message:\n';

     
    address public deprecation_executor;
    bool public safety_deprecation_switch = false;

     
     
     
    mapping (uint256 => Channel) public channels;

     
     
    mapping (bytes32 => uint256) public participants_hash_to_channel_identifier;

     
     
     
     
     
     
     
     
    mapping(bytes32 => UnlockData) private unlock_identifier_to_unlock_data;

    struct Participant {
         
         
         
         
         
        uint256 deposit;

         
         
         
        uint256 withdrawn_amount;

         
         
        bool is_the_closer;

         
         
        bytes32 balance_hash;

         
         
        uint256 nonce;
    }

    enum ChannelState {
        NonExistent,  
        Opened,       
        Closed,       
        Settled,      
        Removed       
    }

    enum MessageTypeId {
        None,
        BalanceProof,
        BalanceProofUpdate,
        Withdraw,
        CooperativeSettle
    }

    struct Channel {
         
         
         
         
         
        uint256 settle_block_number;

        ChannelState state;

        mapping(address => Participant) participants;
    }

    struct SettlementData {
        uint256 deposit;
        uint256 withdrawn;
        uint256 transferred;
        uint256 locked;
    }

    struct UnlockData {
         
        bytes32 locksroot;
         
         
        uint256 locked_amount;
    }

    event ChannelOpened(
        uint256 indexed channel_identifier,
        address indexed participant1,
        address indexed participant2,
        uint256 settle_timeout
    );

    event ChannelNewDeposit(
        uint256 indexed channel_identifier,
        address indexed participant,
        uint256 total_deposit
    );

     
     
     
     

    event ChannelClosed(
        uint256 indexed channel_identifier,
        address indexed closing_participant,
        uint256 indexed nonce
    );

    event ChannelUnlocked(
        uint256 indexed channel_identifier,
        address indexed participant,
        address indexed partner,
        bytes32 locksroot,
        uint256 unlocked_amount,
        uint256 returned_tokens
    );

    event NonClosingBalanceProofUpdated(
        uint256 indexed channel_identifier,
        address indexed closing_participant,
        uint256 indexed nonce
    );

    event ChannelSettled(
        uint256 indexed channel_identifier,
        uint256 participant1_amount,
        uint256 participant2_amount
    );

    modifier onlyDeprecationExecutor() {
        require(msg.sender == deprecation_executor);
        _;
    }

    modifier isSafe() {
        require(safety_deprecation_switch == false);
        _;
    }

    modifier isOpen(uint256 channel_identifier) {
        require(channels[channel_identifier].state == ChannelState.Opened);
        _;
    }

    modifier settleTimeoutValid(uint256 timeout) {
        require(timeout >= settlement_timeout_min);
        require(timeout <= settlement_timeout_max);
        _;
    }

    constructor(
        address _token_address,
        address _secret_registry,
        uint256 _chain_id,
        uint256 _settlement_timeout_min,
        uint256 _settlement_timeout_max,
        address _deprecation_executor
    )
        public
    {
        require(_token_address != address(0x0));
        require(_secret_registry != address(0x0));
        require(_deprecation_executor != address(0x0));
        require(_chain_id > 0);
        require(_settlement_timeout_min > 0);
        require(_settlement_timeout_max > _settlement_timeout_min);
        require(contractExists(_token_address));
        require(contractExists(_secret_registry));

        token = Token(_token_address);

        secret_registry = SecretRegistry(_secret_registry);
        chain_id = _chain_id;
        settlement_timeout_min = _settlement_timeout_min;
        settlement_timeout_max = _settlement_timeout_max;

         
        require(token.totalSupply() > 0);

        deprecation_executor = _deprecation_executor;
    }

    function deprecate() isSafe onlyDeprecationExecutor public {
        safety_deprecation_switch = true;
    }

     
     
     
     
     
     
    function openChannel(address participant1, address participant2, uint256 settle_timeout)
        isSafe
        settleTimeoutValid(settle_timeout)
        public
        returns (uint256)
    {
        bytes32 pair_hash;
        uint256 channel_identifier;

         
        require(token.balanceOf(address(this)) < token_network_deposit_limit);

         
         
        channel_counter += 1;
        channel_identifier = channel_counter;

        pair_hash = getParticipantsHash(participant1, participant2);

         
         
        require(participants_hash_to_channel_identifier[pair_hash] == 0);
        participants_hash_to_channel_identifier[pair_hash] = channel_identifier;

        Channel storage channel = channels[channel_identifier];

         
         
        assert(channel.settle_block_number == 0);
        assert(channel.state == ChannelState.NonExistent);

         
        channel.settle_block_number = settle_timeout;
        channel.state = ChannelState.Opened;

        emit ChannelOpened(
            channel_identifier,
            participant1,
            participant2,
            settle_timeout
        );

        return channel_identifier;
    }

     
     
     
     
     
     
     
     
     
    function setTotalDeposit(
        uint256 channel_identifier,
        address participant,
        uint256 total_deposit,
        address partner
    )
        isSafe
        isOpen(channel_identifier)
        public
    {
        require(channel_identifier == getChannelIdentifier(participant, partner));
        require(total_deposit > 0);
        require(total_deposit <= channel_participant_deposit_limit);

        uint256 added_deposit;
        uint256 channel_deposit;

        Channel storage channel = channels[channel_identifier];
        Participant storage participant_state = channel.participants[participant];
        Participant storage partner_state = channel.participants[partner];

         
        added_deposit = total_deposit - participant_state.deposit;

         
        require(added_deposit > 0);

         

        require(added_deposit <= total_deposit);

         
         
        assert(participant_state.deposit + added_deposit == total_deposit);

         
        require(token.balanceOf(address(this)) + added_deposit <= token_network_deposit_limit);

         
        participant_state.deposit = total_deposit;

         
        channel_deposit = participant_state.deposit + partner_state.deposit;
         
        require(channel_deposit >= participant_state.deposit);

        emit ChannelNewDeposit(
            channel_identifier,
            participant,
            participant_state.deposit
        );

         
        require(token.transferFrom(msg.sender, address(this), added_deposit));
    }

     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function closeChannel(
        uint256 channel_identifier,
        address partner,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes signature
    )
        isOpen(channel_identifier)
        public
    {
        require(channel_identifier == getChannelIdentifier(msg.sender, partner));

        address recovered_partner_address;

        Channel storage channel = channels[channel_identifier];

        channel.state = ChannelState.Closed;
        channel.participants[msg.sender].is_the_closer = true;

         
        channel.settle_block_number += uint256(block.number);

         
         
         
         
        if (nonce > 0) {
            recovered_partner_address = recoverAddressFromBalanceProof(
                channel_identifier,
                balance_hash,
                nonce,
                additional_hash,
                signature
            );
             
            require(partner == recovered_partner_address);

            updateBalanceProofData(
                channel,
                recovered_partner_address,
                nonce,
                balance_hash
            );
        }

        emit ChannelClosed(channel_identifier, msg.sender, nonce);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function updateNonClosingBalanceProof(
        uint256 channel_identifier,
        address closing_participant,
        address non_closing_participant,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes closing_signature,
        bytes non_closing_signature
    )
        external
    {
        require(channel_identifier == getChannelIdentifier(
            closing_participant,
            non_closing_participant
        ));
        require(balance_hash != bytes32(0x0));
        require(nonce > 0);

        address recovered_non_closing_participant;
        address recovered_closing_participant;

        Channel storage channel = channels[channel_identifier];

        require(channel.state == ChannelState.Closed);
         
        require(channel.settle_block_number >= block.number);

         
         
        recovered_non_closing_participant = recoverAddressFromBalanceProofUpdateMessage(
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature,
            non_closing_signature
        );
        require(non_closing_participant == recovered_non_closing_participant);

        recovered_closing_participant = recoverAddressFromBalanceProof(
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature
        );
        require(closing_participant == recovered_closing_participant);

        Participant storage closing_participant_state = channel.participants[closing_participant];
         
        require(closing_participant_state.is_the_closer);

         
        updateBalanceProofData(channel, closing_participant, nonce, balance_hash);

        emit NonClosingBalanceProofUpdated(
            channel_identifier,
            closing_participant,
            nonce
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function settleChannel(
        uint256 channel_identifier,
        address participant1,
        uint256 participant1_transferred_amount,
        uint256 participant1_locked_amount,
        bytes32 participant1_locksroot,
        address participant2,
        uint256 participant2_transferred_amount,
        uint256 participant2_locked_amount,
        bytes32 participant2_locksroot
    )
        public
    {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        require(channel_identifier == getChannelIdentifier(participant1, participant2));

        bytes32 pair_hash;

        pair_hash = getParticipantsHash(participant1, participant2);
        Channel storage channel = channels[channel_identifier];

        require(channel.state == ChannelState.Closed);

         
        require(channel.settle_block_number < block.number);

        Participant storage participant1_state = channel.participants[participant1];
        Participant storage participant2_state = channel.participants[participant2];

        require(verifyBalanceHashData(
            participant1_state,
            participant1_transferred_amount,
            participant1_locked_amount,
            participant1_locksroot
        ));

        require(verifyBalanceHashData(
            participant2_state,
            participant2_transferred_amount,
            participant2_locked_amount,
            participant2_locksroot
        ));

         
         
         
         
         
         
         
         
         
         
         
         
         
         
        (
            participant1_transferred_amount,
            participant2_transferred_amount,
            participant1_locked_amount,
            participant2_locked_amount
        ) = getSettleTransferAmounts(
            participant1_state,
            participant1_transferred_amount,
            participant1_locked_amount,
            participant2_state,
            participant2_transferred_amount,
            participant2_locked_amount
        );

         
        delete channel.participants[participant1];
        delete channel.participants[participant2];
        delete channels[channel_identifier];

         
        delete participants_hash_to_channel_identifier[pair_hash];

         
         
        storeUnlockData(
            channel_identifier,
            participant1,
            participant2,
            participant1_locked_amount,
            participant1_locksroot
        );
        storeUnlockData(
            channel_identifier,
            participant2,
            participant1,
            participant2_locked_amount,
            participant2_locksroot
        );

        emit ChannelSettled(
            channel_identifier,
            participant1_transferred_amount,
            participant2_transferred_amount
        );

         
        if (participant1_transferred_amount > 0) {
            require(token.transfer(participant1, participant1_transferred_amount));
        }

        if (participant2_transferred_amount > 0) {
            require(token.transfer(participant2, participant2_transferred_amount));
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function unlock(
        uint256 channel_identifier,
        address participant,
        address partner,
        bytes merkle_tree_leaves
    )
        public
    {
         
         
        require(channel_identifier != getChannelIdentifier(participant, partner));

         
         
         
        require(channels[channel_identifier].state == ChannelState.NonExistent);

        require(merkle_tree_leaves.length > 0);

        bytes32 unlock_key;
        bytes32 computed_locksroot;
        uint256 unlocked_amount;
        uint256 locked_amount;
        uint256 returned_tokens;

         
         
         
        (computed_locksroot, unlocked_amount) = getMerkleRootAndUnlockedAmount(
            merkle_tree_leaves
        );

         
         
         
         
        unlock_key = getUnlockIdentifier(channel_identifier, partner, participant);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[unlock_key];
        locked_amount = unlock_data.locked_amount;

         
        require(unlock_data.locksroot == computed_locksroot);

         
         
        require(locked_amount > 0);

         
         
        unlocked_amount = min(unlocked_amount, locked_amount);

         
        returned_tokens = locked_amount - unlocked_amount;

         
        delete unlock_identifier_to_unlock_data[unlock_key];

        emit ChannelUnlocked(
            channel_identifier,
            participant,
            partner,
            computed_locksroot,
            unlocked_amount,
            returned_tokens
        );

         
         
        if (unlocked_amount > 0) {
            require(token.transfer(participant, unlocked_amount));
        }

         
        if (returned_tokens > 0) {
            require(token.transfer(partner, returned_tokens));
        }

         
        assert(locked_amount >= returned_tokens);
        assert(locked_amount >= unlocked_amount);
    }

     

     
     
     
     
     
     
    function getChannelIdentifier(address participant, address partner)
        view
        public
        returns (uint256)
    {
        require(participant != address(0x0));
        require(partner != address(0x0));
        require(participant != partner);

        bytes32 pair_hash = getParticipantsHash(participant, partner);
        return participants_hash_to_channel_identifier[pair_hash];
    }

     
     
     
     
     
     
    function getChannelInfo(
        uint256 channel_identifier,
        address participant1,
        address participant2
    )
        view
        external
        returns (uint256, ChannelState)
    {
        bytes32 unlock_key1;
        bytes32 unlock_key2;

        Channel storage channel = channels[channel_identifier];
        ChannelState state = channel.state;   

        if (state == ChannelState.NonExistent &&
            channel_identifier > 0 &&
            channel_identifier <= channel_counter
        ) {
             
             
             
             
            state = ChannelState.Settled;

             
             
            unlock_key1 = getUnlockIdentifier(channel_identifier, participant1, participant2);
            UnlockData storage unlock_data1 = unlock_identifier_to_unlock_data[unlock_key1];

            unlock_key2 = getUnlockIdentifier(channel_identifier, participant2, participant1);
            UnlockData storage unlock_data2 = unlock_identifier_to_unlock_data[unlock_key2];

            if (unlock_data1.locked_amount == 0 && unlock_data2.locked_amount == 0) {
                state = ChannelState.Removed;
            }
        }

        return (
            channel.settle_block_number,
            state
        );
    }

     
     
     
     
     
     
     
     
     
    function getChannelParticipantInfo(
            uint256 channel_identifier,
            address participant,
            address partner
    )
        view
        external
        returns (uint256, uint256, bool, bytes32, uint256, bytes32, uint256)
    {
        bytes32 unlock_key;

        Participant storage participant_state = channels[channel_identifier].participants[
            participant
        ];
        unlock_key = getUnlockIdentifier(channel_identifier, participant, partner);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[unlock_key];

        return (
            participant_state.deposit,
            participant_state.withdrawn_amount,
            participant_state.is_the_closer,
            participant_state.balance_hash,
            participant_state.nonce,
            unlock_data.locksroot,
            unlock_data.locked_amount
        );
    }

     
     
     
     
    function getParticipantsHash(address participant, address partner)
        pure
        public
        returns (bytes32)
    {
        require(participant != address(0x0));
        require(partner != address(0x0));
        require(participant != partner);

        if (participant < partner) {
            return keccak256(abi.encodePacked(participant, partner));
        } else {
            return keccak256(abi.encodePacked(partner, participant));
        }
    }

    function getUnlockIdentifier(
        uint256 channel_identifier,
        address participant,
        address partner
    )
        pure
        public
        returns (bytes32)
    {
        require(participant != partner);
        return keccak256(abi.encodePacked(channel_identifier, participant, partner));
    }

    function updateBalanceProofData(
        Channel storage channel,
        address participant,
        uint256 nonce,
        bytes32 balance_hash
    )
        internal
    {
        Participant storage participant_state = channel.participants[participant];

         
         
        require(nonce > participant_state.nonce);

        participant_state.nonce = nonce;
        participant_state.balance_hash = balance_hash;
    }

    function storeUnlockData(
        uint256 channel_identifier,
        address participant,
        address partner,
        uint256 locked_amount,
        bytes32 locksroot
    )
        internal
    {
         
         
        if (locked_amount == 0 || locksroot == 0) {
            return;
        }

        bytes32 key = getUnlockIdentifier(channel_identifier, participant, partner);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[key];
        unlock_data.locksroot = locksroot;
        unlock_data.locked_amount = locked_amount;
    }

    function getChannelAvailableDeposit(
        Participant storage participant1_state,
        Participant storage participant2_state
    )
        view
        internal
        returns (uint256 total_available_deposit)
    {
        total_available_deposit = (
            participant1_state.deposit +
            participant2_state.deposit -
            participant1_state.withdrawn_amount -
            participant2_state.withdrawn_amount
        );
    }

     
     
     
     
    function getSettleTransferAmounts(
        Participant storage participant1_state,
        uint256 participant1_transferred_amount,
        uint256 participant1_locked_amount,
        Participant storage participant2_state,
        uint256 participant2_transferred_amount,
        uint256 participant2_locked_amount
    )
        view
        private
        returns (uint256, uint256, uint256, uint256)
    {
         
         
         
         
         

         
         
         

         
         
         

         
         

         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         

        uint256 participant1_amount;
        uint256 participant2_amount;
        uint256 total_available_deposit;

        SettlementData memory participant1_settlement;
        SettlementData memory participant2_settlement;

        participant1_settlement.deposit = participant1_state.deposit;
        participant1_settlement.withdrawn = participant1_state.withdrawn_amount;
        participant1_settlement.transferred = participant1_transferred_amount;
        participant1_settlement.locked = participant1_locked_amount;

        participant2_settlement.deposit = participant2_state.deposit;
        participant2_settlement.withdrawn = participant2_state.withdrawn_amount;
        participant2_settlement.transferred = participant2_transferred_amount;
        participant2_settlement.locked = participant2_locked_amount;

         
        total_available_deposit = getChannelAvailableDeposit(
            participant1_state,
            participant2_state
        );

         
         
         
         
        participant1_amount = getMaxPossibleReceivableAmount(
            participant1_settlement,
            participant2_settlement
        );

         
         
         
         
        participant1_amount = min(participant1_amount, total_available_deposit);

         
         
        participant2_amount = total_available_deposit - participant1_amount;

         
         
         
         
         
        (participant1_amount, participant2_locked_amount) = failsafe_subtract(
            participant1_amount,
            participant2_locked_amount
        );

         
         
         
         
         
        (participant2_amount, participant1_locked_amount) = failsafe_subtract(
            participant2_amount,
            participant1_locked_amount
        );

         
         
        assert(participant1_amount <= total_available_deposit);
        assert(participant2_amount <= total_available_deposit);
         
        assert(total_available_deposit == (
            participant1_amount +
            participant2_amount +
            participant1_locked_amount +
            participant2_locked_amount
        ));

        return (
            participant1_amount,
            participant2_amount,
            participant1_locked_amount,
            participant2_locked_amount
        );
    }

    function getMaxPossibleReceivableAmount(
        SettlementData participant1_settlement,
        SettlementData participant2_settlement
    )
        pure
        internal
        returns (uint256)
    {
        uint256 participant1_max_transferred;
        uint256 participant2_max_transferred;
        uint256 participant1_net_max_received;
        uint256 participant1_max_amount;

         
         
         
        participant1_max_transferred = failsafe_addition(
            participant1_settlement.transferred,
            participant1_settlement.locked
        );

         
         
         
        participant2_max_transferred = failsafe_addition(
            participant2_settlement.transferred,
            participant2_settlement.locked
        );

         
         
         
         
         
        require(participant2_max_transferred >= participant1_max_transferred);

        assert(participant1_max_transferred >= participant1_settlement.transferred);
        assert(participant2_max_transferred >= participant2_settlement.transferred);

         
        participant1_net_max_received = (
            participant2_max_transferred -
            participant1_max_transferred
        );

         
         
        participant1_max_amount = failsafe_addition(
            participant1_net_max_received,
            participant1_settlement.deposit
        );

         
        (participant1_max_amount, ) = failsafe_subtract(
            participant1_max_amount,
            participant1_settlement.withdrawn
        );
        return participant1_max_amount;
    }

    function verifyBalanceHashData(
        Participant storage participant,
        uint256 transferred_amount,
        uint256 locked_amount,
        bytes32 locksroot
    )
        view
        internal
        returns (bool)
    {
         
         
        if (participant.balance_hash == 0 &&
            transferred_amount == 0 &&
            locked_amount == 0 &&
            locksroot == 0
        ) {
            return true;
        }

         
         
        return participant.balance_hash == keccak256(abi.encodePacked(
            transferred_amount,
            locked_amount,
            locksroot
        ));
    }

    function recoverAddressFromBalanceProof(
        uint256 channel_identifier,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes signature
    )
        view
        internal
        returns (address signature_address)
    {
         
        string memory message_length = '212';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(MessageTypeId.BalanceProof),
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash
        ));

        signature_address = ECVerify.ecverify(message_hash, signature);
    }

    function recoverAddressFromBalanceProofUpdateMessage(
        uint256 channel_identifier,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes closing_signature,
        bytes non_closing_signature
    )
        view
        internal
        returns (address signature_address)
    {
         
        string memory message_length = '277';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(MessageTypeId.BalanceProofUpdate),
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature
        ));

        signature_address = ECVerify.ecverify(message_hash, non_closing_signature);
    }

     

     

     
     
     
    function getMerkleRootAndUnlockedAmount(bytes merkle_tree_leaves)
        view
        internal
        returns (bytes32, uint256)
    {
        uint256 length = merkle_tree_leaves.length;

         
         
        require(length % 96 == 0);

        uint256 i;
        uint256 total_unlocked_amount;
        uint256 unlocked_amount;
        bytes32 lockhash;
        bytes32 merkle_root;

        bytes32[] memory merkle_layer = new bytes32[](length / 96 + 1);

        for (i = 32; i < length; i += 96) {
            (lockhash, unlocked_amount) = getLockDataFromMerkleTree(merkle_tree_leaves, i);
            total_unlocked_amount += unlocked_amount;
            merkle_layer[i / 96] = lockhash;
        }

        length /= 96;

        while (length > 1) {
            if (length % 2 != 0) {
                merkle_layer[length] = merkle_layer[length - 1];
                length += 1;
            }

            for (i = 0; i < length - 1; i += 2) {
                if (merkle_layer[i] == merkle_layer[i + 1]) {
                    lockhash = merkle_layer[i];
                } else if (merkle_layer[i] < merkle_layer[i + 1]) {
                    lockhash = keccak256(abi.encodePacked(merkle_layer[i], merkle_layer[i + 1]));
                } else {
                    lockhash = keccak256(abi.encodePacked(merkle_layer[i + 1], merkle_layer[i]));
                }
                merkle_layer[i / 2] = lockhash;
            }
            length = i / 2;
        }

        merkle_root = merkle_layer[0];

        return (merkle_root, total_unlocked_amount);
    }

    function getLockDataFromMerkleTree(bytes merkle_tree_leaves, uint256 offset)
        view
        internal
        returns (bytes32, uint256)
    {
        uint256 expiration_block;
        uint256 locked_amount;
        uint256 reveal_block;
        bytes32 secrethash;
        bytes32 lockhash;

        if (merkle_tree_leaves.length <= offset) {
            return (lockhash, 0);
        }

        assembly {
            expiration_block := mload(add(merkle_tree_leaves, offset))
            locked_amount := mload(add(merkle_tree_leaves, add(offset, 32)))
            secrethash := mload(add(merkle_tree_leaves, add(offset, 64)))
        }

         
        lockhash = keccak256(abi.encodePacked(expiration_block, locked_amount, secrethash));

         
         
         
         
        reveal_block = secret_registry.getSecretRevealBlockHeight(secrethash);
        if (reveal_block == 0 || expiration_block <= reveal_block) {
            locked_amount = 0;
        }

        return (lockhash, locked_amount);
    }

    function min(uint256 a, uint256 b) pure internal returns (uint256)
    {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) pure internal returns (uint256)
    {
        return a > b ? a : b;
    }

     
     
     
     
     
    function failsafe_subtract(uint256 a, uint256 b)
        pure
        internal
        returns (uint256, uint256)
    {
        return a > b ? (a - b, b) : (0, a);
    }

     
     
     
     
     
    function failsafe_addition(uint256 a, uint256 b)
        pure
        internal
        returns (uint256)
    {
        uint256 sum = a + b;
        return sum >= a ? sum : MAX_SAFE_UINT256;
    }
}