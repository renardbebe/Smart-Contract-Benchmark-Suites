 

pragma solidity ^0.4.13;

library ECRecovery {

     
    function recover(bytes32 hash, bytes sig)
        internal
        pure
        returns (address)
    {
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

     
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
         
         
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract Htlc is DSMath {
    using ECRecovery for bytes32;

     

     
    struct Multisig {  
        address owner;  
        address authority;  
        uint deposit;  
        uint unlockTime;  
    }

    struct AtomicSwap {  
        bytes32 msigId;  
        address initiator;  
        address beneficiary;  
        uint amount;  
        uint fee;  
        uint expirationTime;  
        bytes32 hashedSecret;  
    }

     

    address constant FEE_RECIPIENT = 0x478189a0aF876598C8a70Ce8896960500455A949;
    uint constant MAX_BATCH_ITERATIONS = 25;  
    mapping (bytes32 => Multisig) public multisigs;
    mapping (bytes32 => AtomicSwap) public atomicswaps;
    mapping (bytes32 => bool) public isAntecedentHashedSecret;

     

    event MultisigInitialised(bytes32 msigId);
    event MultisigReparametrized(bytes32 msigId);
    event AtomicSwapInitialised(bytes32 swapId);

     

     

     
    function spendFromMultisig(bytes32 msigId, uint amount, address recipient)
        internal
    {
        multisigs[msigId].deposit = sub(multisigs[msigId].deposit, amount);
        if (multisigs[msigId].deposit == 0)
            delete multisigs[msigId];
        recipient.transfer(amount);
    }

     

     
    function initialiseMultisig(address authority, uint unlockTime)
        public
        payable
        returns (bytes32 msigId)
    {
         
        require(msg.sender != authority);
        require(msg.value > 0);
         
        msigId = keccak256(
            msg.sender,
            authority,
            msg.value,
            unlockTime
        );
        emit MultisigInitialised(msigId);
         
        Multisig storage multisig = multisigs[msigId];
        if (multisig.deposit == 0) {  
             
            multisig.owner = msg.sender;
            multisig.authority = authority;
        }
         
        reparametrizeMultisig(msigId, unlockTime);
    }

     
    function reparametrizeMultisig(bytes32 msigId, uint unlockTime)
        public
        payable
    {
        require(multisigs[msigId].owner == msg.sender);
        Multisig storage multisig = multisigs[msigId];
        multisig.deposit = add(multisig.deposit, msg.value);
        assert(multisig.unlockTime <= unlockTime);  
        multisig.unlockTime = unlockTime;
        emit MultisigReparametrized(msigId);
    }

     
    function earlyResolve(bytes32 msigId, uint amount, bytes sig)
        public
    {
         
        require(
            multisigs[msigId].owner == msg.sender ||
            multisigs[msigId].authority == msg.sender
        );
         
        address otherAuthority = multisigs[msigId].owner == msg.sender ?
            multisigs[msigId].authority :
            multisigs[msigId].owner;
        require(otherAuthority == msigId.toEthSignedMessageHash().recover(sig));
         
        spendFromMultisig(msigId, amount, multisigs[msigId].owner);
    }

     
    function timeoutResolve(bytes32 msigId, uint amount)
        public
    {
         
        require(now >= multisigs[msigId].unlockTime);
         
        spendFromMultisig(msigId, amount, multisigs[msigId].owner);
    }

     
    function convertIntoHtlc(bytes32 msigId, address beneficiary, uint amount, uint fee, uint expirationTime, bytes32 hashedSecret)
        public
        returns (bytes32 swapId)
    {
         
        require(multisigs[msigId].owner == msg.sender);
        require(multisigs[msigId].deposit >= amount + fee);  
        require(
            now <= expirationTime &&
            expirationTime <= min(now + 1 days, multisigs[msigId].unlockTime)
        );  
        require(amount > 0);  
        require(!isAntecedentHashedSecret[hashedSecret]);
        isAntecedentHashedSecret[hashedSecret] = true;
         
        multisigs[msigId].deposit = sub(multisigs[msigId].deposit, add(amount, fee));
         
        swapId = keccak256(
            msigId,
            msg.sender,
            beneficiary,
            amount,
            fee,
            expirationTime,
            hashedSecret
        );
        emit AtomicSwapInitialised(swapId);
         
        AtomicSwap storage swap = atomicswaps[swapId];
        swap.msigId = msigId;
        swap.initiator = msg.sender;
        swap.beneficiary = beneficiary;
        swap.amount = amount;
        swap.fee = fee;
        swap.expirationTime = expirationTime;
        swap.hashedSecret = hashedSecret;
         
        FEE_RECIPIENT.transfer(fee);
    }

     
    function batchConvertIntoHtlc(
        bytes32[] msigIds,
        address[] beneficiaries,
        uint[] amounts,
        uint[] fees,
        uint[] expirationTimes,
        bytes32[] hashedSecrets
    )
        public
        returns (bytes32[] swapId)
    {
        require(msigIds.length <= MAX_BATCH_ITERATIONS);
        for (uint i = 0; i < msigIds.length; ++i)
            convertIntoHtlc(
                msigIds[i],
                beneficiaries[i],
                amounts[i],
                fees[i],
                expirationTimes[i],
                hashedSecrets[i]
            );  
    }

     
    function regularTransfer(bytes32 swapId, bytes32 secret)
        public
    {
         
        require(sha256(secret) == atomicswaps[swapId].hashedSecret);
        uint amount = atomicswaps[swapId].amount;
        address beneficiary = atomicswaps[swapId].beneficiary;
         
        delete atomicswaps[swapId];
         
        beneficiary.transfer(amount);
    }

     
    function batchRegularTransfers(bytes32[] swapIds, bytes32[] secrets)
        public
    {
        require(swapIds.length <= MAX_BATCH_ITERATIONS);
        for (uint i = 0; i < swapIds.length; ++i)
            regularTransfer(swapIds[i], secrets[i]);  
    }

     
    function reclaimExpiredSwap(bytes32 msigId, bytes32 swapId)
        public
    {
         
        require(
            multisigs[msigId].owner == msg.sender ||
            multisigs[msigId].authority == msg.sender
        );
         
        require(msigId == atomicswaps[swapId].msigId);
         
        require(now >= atomicswaps[swapId].expirationTime);
        uint amount = atomicswaps[swapId].amount;
        delete atomicswaps[swapId];
        multisigs[msigId].deposit = add(multisigs[msigId].deposit, amount);
    }

     
    function batchReclaimExpiredSwaps(bytes32 msigId, bytes32[] swapIds)
        public
    {
        require(swapIds.length <= MAX_BATCH_ITERATIONS);  
        for (uint i = 0; i < swapIds.length; ++i)
            reclaimExpiredSwap(msigId, swapIds[i]);  
    }
}