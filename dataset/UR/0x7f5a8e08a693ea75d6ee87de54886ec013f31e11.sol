 

 

pragma solidity ^0.5.2;

 
library Dictionary {
    uint private constant NULL = 0;

    struct Node {
        uint prev;
        uint next;
        bytes data;
        bool initialized;
    }

    struct Data {
        mapping(uint => Node) list;
        uint firstNodeId;
        uint lastNodeId;
        uint len;
    }

    function insertAfter(
        Data storage self,
        uint afterId,
        uint id,
        bytes memory data
    ) internal {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        self.list[id].prev = afterId;
        if (self.list[afterId].next == NULL) {
            self.list[id].next = NULL;
            self.lastNodeId = id;
        } else {
            self.list[id].next = self.list[afterId].next;
            self.list[self.list[afterId].next].prev = id;
        }
        self.list[id].data = data;
        self.list[id].initialized = true;
        self.list[afterId].next = id;
        self.len++;
    }

    function insertBefore(
        Data storage self,
        uint beforeId,
        uint id,
        bytes memory data
    ) internal {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        self.list[id].next = beforeId;
        if (self.list[beforeId].prev == NULL) {
            self.list[id].prev = NULL;
            self.firstNodeId = id;
        } else {
            self.list[id].prev = self.list[beforeId].prev;
            self.list[self.list[beforeId].prev].next = id;
        }
        self.list[id].data = data;
        self.list[id].initialized = true;
        self.list[beforeId].prev = id;
        self.len++;
    }

    function insertBeginning(Data storage self, uint id, bytes memory data)
        internal
    {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        if (self.firstNodeId == NULL) {
            self.firstNodeId = id;
            self.lastNodeId = id;
            self.list[id] = Node({
                prev: 0,
                next: 0,
                data: data,
                initialized: true
            });
            self.len++;
        } else insertBefore(self, self.firstNodeId, id, data);
    }

    function insertEnd(Data storage self, uint id, bytes memory data) internal {
        if (self.lastNodeId == NULL) insertBeginning(self, id, data);
        else insertAfter(self, self.lastNodeId, id, data);
    }

    function set(Data storage self, uint id, bytes memory data) internal {
        insertEnd(self, id, data);
    }

    function get(Data storage self, uint id)
        internal
        view
        returns (bytes memory)
    {
        return self.list[id].data;
    }

    function remove(Data storage self, uint id) internal returns (bool) {
        uint nextId = self.list[id].next;
        uint prevId = self.list[id].prev;

        if (prevId == NULL) self.firstNodeId = nextId;  
        else self.list[prevId].next = nextId;

        if (nextId == NULL) self.lastNodeId = prevId;  
        else self.list[nextId].prev = prevId;

        delete self.list[id];
        self.len--;

        return true;
    }

    function getSize(Data storage self) internal view returns (uint) {
        return self.len;
    }

    function next(Data storage self, uint id) internal view returns (uint) {
        return self.list[id].next;
    }

    function prev(Data storage self, uint id) internal view returns (uint) {
        return self.list[id].prev;
    }

    function keys(Data storage self) internal view returns (uint[] memory) {
        uint[] memory arr = new uint[](self.len);
        uint node = self.firstNodeId;
        for (uint i = 0; i < self.len; i++) {
            arr[i] = node;
            node = next(self, node);
        }
        return arr;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;




 

 
contract ReverseRegistrar {
    function setName(string memory name) public returns (bytes32);
}

contract Etherclear {
     
    using Dictionary for Dictionary.Data;

     

     
     
     
     
     
    event PaymentOpened(
        uint txnId,
        uint holdTime,
        uint openTime,
        uint closeTime,
        address token,
        uint sendAmount,
        address indexed sender,
        address indexed recipient,
        bytes codeHash
    );
    event PaymentClosed(
        uint txnId,
        uint holdTime,
        uint openTime,
        uint closeTime,
        address token,
        uint sendAmount,
        address indexed sender,
        address indexed recipient,
        bytes codeHash,
        uint state
    );

     
     
    enum PaymentState {OPEN, COMPLETED, CANCELLED}

     
     
    struct Payment {
         
        uint holdTime;
        uint paymentOpenTime;
        uint paymentCloseTime;
         
        address token;
        uint sendAmount;
        address payable sender;
        address payable recipient;
        bytes codeHash;
        PaymentState state;
    }

    ReverseRegistrar reverseRegistrar;

     
     
     
    struct RetrieveFundsRequest {
        uint txnId;
        address sender;
        address recipient;
        string passphrase;
    }

     
    mapping(address => Dictionary.Data) recipientPayments;
     
    mapping(address => Dictionary.Data) senderPayments;
     
    mapping(uint => Payment) allPayments;

     
    address payable owner;
     
     
     
    uint baseFee;
    uint paymentFee;
     
    mapping(address => mapping(address => uint)) public tokens;

     
     
     
    bool createPaymentEnabled;
     
    bool retrieveFundsEnabled;

    address constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    string private constant RETRIEVE_FUNDS_REQUEST_TYPE = "RetrieveFundsRequest(uint256 txnId,address sender,address recipient,string passphrase)";
    string private constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(EIP712_DOMAIN_TYPE)
    );
    bytes32 private constant RETRIEVE_FUNDS_REQUEST_TYPEHASH = keccak256(
        abi.encodePacked(RETRIEVE_FUNDS_REQUEST_TYPE)
    );
    bytes32 private DOMAIN_SEPARATOR;
    uint256 chainId;

    function hashRetrieveFundsRequest(RetrieveFundsRequest memory request)
        private
        view
        returns (bytes32 hash)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        RETRIEVE_FUNDS_REQUEST_TYPEHASH,
                        request.txnId,
                        request.sender,
                        request.recipient,
                        keccak256(bytes(request.passphrase))
                    )
                )
            )
        );
    }

    function verify(
        address signer,
        RetrieveFundsRequest memory request,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) private view returns (address result) {
        return ecrecover(hashRetrieveFundsRequest(request), sigV, sigR, sigS);
    }

     
    function checkRetrieveSignature(
        uint256 txnId,
        address sender,
        address recipient,
        string memory passphrase,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (address result) {
        RetrieveFundsRequest memory request = RetrieveFundsRequest(
            txnId,
            sender,
            recipient,
            passphrase
        );
        address signer = ecrecover(
            hashRetrieveFundsRequest(request),
            sigV,
            sigR,
            sigS
        );
        return verify(recipient, request, sigR, sigS, sigV);
    }

    constructor(uint256 _chainId) public {
        owner = msg.sender;
        baseFee = 0.001 ether;
        paymentFee = 0.005 ether;
        createPaymentEnabled = true;
        retrieveFundsEnabled = true;
        chainId = _chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Etherclear"),
                keccak256("1"),
                chainId,
                verifyingContract,
                salt
            )
        );
    }

    function getChainId() public view returns (uint256 networkID) {
        return chainId;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner is allowed to use this function."
        );
        _;
    }

     
    function setENS(address reverseRegistrarAddr, string memory name)
        public
        onlyOwner
    {
        reverseRegistrar = ReverseRegistrar(reverseRegistrarAddr);
        reverseRegistrar.setName(name);

    }

    function withdrawFees(address token) external onlyOwner {
         
        uint total = tokens[token][owner];
        tokens[token][owner] = 0;
        if (token == address(0)) {
            owner.transfer(total);
        } else {
            require(
                IERC20(token).transfer(owner, total),
                "Could not successfully withdraw token"
            );
        }
    }

    function viewBalance(address token, address user)
        external
        view
        returns (uint balance)
    {
        return tokens[token][user];
    }

     
     
    function changeBaseFee(uint newFee) external onlyOwner {
        baseFee = newFee;
    }
    function changePaymentFee(uint newFee) external onlyOwner {
        paymentFee = newFee;
    }

    function getBaseFee() public view returns (uint feeAmt) {
        return baseFee;
    }

    function getPaymentFee() public view returns (uint feeAmt) {
        return paymentFee;
    }

    function getPaymentsForSender()
        external
        view
        returns (uint[] memory result)
    {
        Dictionary.Data storage payments = senderPayments[msg.sender];
        uint[] memory keys = payments.keys();
        return keys;

    }

    function disableRetrieveFunds(bool disabled) public onlyOwner {
        retrieveFundsEnabled = !disabled;
    }

    function disableCreatePayment(bool disabled) public onlyOwner {
        createPaymentEnabled = !disabled;
    }

    function getPaymentsForRecipient()
        external
        view
        returns (uint[] memory result)
    {
        Dictionary.Data storage payments = recipientPayments[msg.sender];
        uint[] memory keys = payments.keys();
        return keys;
    }

    function getPaymentInfo(uint paymentID)
        external
        view
        returns (
        uint holdTime,
        uint paymentOpenTime,
        uint paymentCloseTime,
        address token,
        uint sendAmount,
        address sender,
        address recipient,
        bytes memory codeHash,
        uint state
    )
    {
        Payment memory txn = allPayments[paymentID];
        return (txn.holdTime, txn.paymentOpenTime, txn.paymentCloseTime, txn.token, txn.sendAmount, txn.sender, txn.recipient, txn.codeHash, uint(
            txn.state
        ));
    }

     
     
    function cancelPayment(uint txnId) external {
         
        Payment memory txn = allPayments[txnId];
        require(
            txn.sender == msg.sender,
            "Payment sender does not match message sender."
        );
        require(
            txn.state == PaymentState.OPEN,
            "Payment must be open to cancel."
        );

         
        txn.paymentCloseTime = now;
        txn.state = PaymentState.CANCELLED;

        delete allPayments[txnId];
        recipientPayments[txn.recipient].remove(txnId);
        senderPayments[txn.sender].remove(txnId);

         
        if (txn.token == address(0)) {
            tokens[address(0)][txn.sender] = SafeMath.sub(
                tokens[address(0)][txn.sender],
                txn.sendAmount
            );
            txn.sender.transfer(txn.sendAmount);
        } else {
            withdrawToken(txn.token, txn.sender, txn.sender, txn.sendAmount);
        }

        emit PaymentClosed(
            txnId,
            txn.holdTime,
            txn.paymentOpenTime,
            txn.paymentCloseTime,
            txn.token,
            txn.sendAmount,
            txn.sender,
            txn.recipient,
            txn.codeHash,
            uint(txn.state)
        );
    }

     
     
     
    function transferToken(
        address token,
        address user,
        uint originalAmount,
        uint feeAmount
    ) internal {
        require(token != address(0));
         
         
        require(
            IERC20(token).transferFrom(
                user,
                address(this),
                SafeMath.add(originalAmount, feeAmount)
            )
        );
         
        tokens[token][user] = SafeMath.add(
            tokens[token][msg.sender],
            originalAmount
        );
        tokens[token][owner] = SafeMath.add(tokens[token][owner], feeAmount);
    }

     
     
     
    function withdrawToken(
        address token,
        address userFrom,
        address userTo,
        uint amount
    ) internal {
        require(token != address(0));
        require(IERC20(token).transfer(userTo, amount));
        tokens[token][userFrom] = SafeMath.sub(tokens[token][userFrom], amount);
    }

     
     
    function createPayment(
        uint amount,
        address payable recipient,
        uint holdTime,
        bytes calldata codeHash
    ) external payable {
        return createTokenPayment(
            address(0),
            amount,
            recipient,
            holdTime,
            codeHash
        );

    }

     
     
     
     
     
     
    function getBalance(address token) external view returns (uint amt) {
        return tokens[token][msg.sender];
    }

    function getPaymentId(address recipient, bytes memory codeHash)
        public
        pure
        returns (uint result)
    {
        bytes memory txnIdBytes = abi.encodePacked(
            keccak256(abi.encodePacked(codeHash, recipient))
        );
        uint txnId = sliceUint(txnIdBytes);
        return txnId;
    }
     
     
     
     
     
     
    function createTokenPayment(
        address token,
        uint amount,
        address payable recipient,
        uint holdTime,
        bytes memory codeHash
    ) public payable {
         
        require(createPaymentEnabled, "The create payments functionality is currently disabled");
        uint paymentFeeTotal = uint(
            SafeMath.mul(paymentFee, amount) / (1 ether)
        );
        if (token == address(0)) {
            require(
                msg.value >= (SafeMath.add(
                    SafeMath.add(amount, baseFee),
                    paymentFeeTotal
                )),
                "Message value is not enough to cover amount and fees"
            );
        } else {
            require(
                msg.value >= baseFee,
                "Message value is not enough to cover base fee"
            );
             
             
             
        }

         
        Dictionary.Data storage sendertxns = senderPayments[msg.sender];
         
         
        Dictionary.Data storage recipienttxns = recipientPayments[recipient];

         
         
         
         
        uint txnId = getPaymentId(recipient, codeHash);
         
        require(
            allPayments[txnId].sender == address(0),
            "Payment ID must be unique. Use a different passphrase hash."
        );

         
        bytes memory val = "\x20";
        sendertxns.set(txnId, val);
        recipienttxns.set(txnId, val);

         
        Payment memory txn = Payment(
            holdTime,
            now,
            0,
            token,
            amount,
            msg.sender,
            recipient,
            codeHash,
            PaymentState.OPEN
        );

        allPayments[txnId] = txn;

         
        if (token == address(0)) {
             
            tokens[address(0)][msg.sender] = SafeMath.add(
                tokens[address(0)][msg.sender],
                amount
            );

             
            tokens[address(0)][owner] = SafeMath.add(
                tokens[address(0)][owner],
                SafeMath.sub(msg.value, amount)
            );

        } else {
             
            tokens[address(0)][owner] = SafeMath.add(
                tokens[address(0)][owner],
                msg.value
            );
             
            transferToken(token, msg.sender, amount, paymentFeeTotal);
        }

         
        emit PaymentOpened(
            txnId,
            txn.holdTime,
            txn.paymentOpenTime,
            txn.paymentCloseTime,
            txn.token,
            txn.sendAmount,
            txn.sender,
            txn.recipient,
            txn.codeHash
        );

    }

     
     
    function retrieveFundsForRecipient(
        uint256 txnId,
        address sender,
        address recipient,
        string memory passphrase,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public {
        RetrieveFundsRequest memory request = RetrieveFundsRequest(
            txnId,
            sender,
            recipient,
            passphrase
        );
        address signer = ecrecover(
            hashRetrieveFundsRequest(request),
            sigV,
            sigR,
            sigS
        );

        require(
            recipient == signer,
            "The message recipient must be the same as the signer of the message"
        );
        Payment memory txn = allPayments[txnId];
        require(
            txn.recipient == recipient,
            "The payment's recipient must be the same as signer of the message"
        );
        retrieveFunds(txn, txnId, passphrase);
    }

     
    function retrieveFundsAsRecipient(uint txnId, string memory code) public {
        Payment memory txn = allPayments[txnId];

         
        require(
            txn.recipient == msg.sender,
            "Message sender must match payment recipient"
        );
        retrieveFunds(txn, txnId, code);
    }

     
     
     
     
    function retrieveFunds(Payment memory txn, uint txnId, string memory code)
        private
    {
    require(retrieveFundsEnabled, "The retrieve funds functionality is currently disabled.");
        require(
            txn.state == PaymentState.OPEN,
            "Payment must be open to retrieve funds"
        );
         
        bytes memory actualHash = abi.encodePacked(
            keccak256(abi.encodePacked(code, txn.recipient))
        );
     
    require(
            sliceUint(actualHash) == sliceUint(txn.codeHash),
            "Passphrase is not correct"
        );

         
        require(
            (txn.paymentOpenTime + txn.holdTime) > now,
            "Hold time has already expired"
        );

         
        txn.paymentCloseTime = now;
        txn.state = PaymentState.COMPLETED;

        delete allPayments[txnId];
        recipientPayments[txn.recipient].remove(txnId);
        senderPayments[txn.sender].remove(txnId);

         
        if (txn.token == address(0)) {
             
             
            txn.recipient.transfer(txn.sendAmount);
            tokens[address(0)][txn.sender] = SafeMath.sub(
                tokens[address(0)][txn.sender],
                txn.sendAmount
            );

        } else {
            withdrawToken(txn.token, txn.sender, txn.recipient, txn.sendAmount);
        }

        emit PaymentClosed(
            txnId,
            txn.holdTime,
            txn.paymentOpenTime,
            txn.paymentCloseTime,
            txn.token,
            txn.sendAmount,
            txn.sender,
            txn.recipient,
            txn.codeHash,
            uint(txn.state)
        );

    }

     
     
    function sliceUint(bytes memory bs) public pure returns (uint) {
        uint start = 0;
        if (bs.length < start + 32) {
            return 0;
        }
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

}