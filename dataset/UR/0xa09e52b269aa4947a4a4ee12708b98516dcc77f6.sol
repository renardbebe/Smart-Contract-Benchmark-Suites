 

pragma solidity ^0.5.0;


library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }

     
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

     
    function P1()
        internal pure returns (G1Point memory)
    {
        return G1Point(1, 2);
    }

     
    function P2() internal pure returns (G2Point memory) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }

     
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
         
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

     
    function pointAdd(G1Point memory p1, G1Point memory p2)
        internal view returns (G1Point memory r)
    {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 6, input, 0xc0, r, 0x60)
        }
        require(success);
    }

     
     
    function pointMul(G1Point memory p, uint s)
        internal view returns (G1Point memory r)
    {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 7, input, 0x80, r, 0x60)
        }
        require (success);
    }

     
     
     
     
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal view returns (bool)
    {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas, 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

     
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2)
        internal view returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
     
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    )
        internal view returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

     
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    )
        internal view returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}


library Verifier
{
    using Pairing for Pairing.G1Point;
    using Pairing for Pairing.G2Point;

    function scalarField ()
        internal pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    struct VerifyingKey
    {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gammaABC;
    }

    struct Proof
    {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    struct ProofWithInput
    {
        Proof proof;
        uint256[] input;
    }


    function negateY( uint256 Y )
        internal 
        pure 
        returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }


     
    function verify (uint256[14] memory in_vk, uint256[] memory vk_gammaABC, uint256[8] memory in_proof, uint256[] memory proof_inputs)
        internal 
        view 
        returns (bool)
    {
        require( ((vk_gammaABC.length / 2) - 1) == proof_inputs.length );
        
         
        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint m = 2;

         
        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];

         
        for (uint i = 0; i < proof_inputs.length; i++) {
            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];

            assembly {
                 
                success := staticcall(sub(gas, 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            require(success);
            
            assembly {
                 
                success := staticcall(sub(gas, 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            require(success);
        }
        
        uint[24] memory input = [
             
            in_proof[0], in_proof[1],                            
            in_proof[2], in_proof[3], in_proof[4], in_proof[5],  

             
            in_vk[0], negateY(in_vk[1]),                         
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],              

             
            add_input[0], negateY(add_input[1]),                 
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],              

             
            in_proof[6], negateY(in_proof[7]),                   
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]           
        ];

        uint[1] memory out;
        assembly {
            success := staticcall(sub(gas, 2000), 8, input, 768, out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }


    function verify(VerifyingKey memory vk, ProofWithInput memory pwi)
        internal 
        view 
        returns (bool)
    {
        return verify(vk, pwi.proof, pwi.input);
    }


    function verify(VerifyingKey memory vk, Proof memory proof, uint256[] memory input)
        internal 
        view 
        returns (bool)
    {
        require(input.length + 1 == vk.gammaABC.length);

         
        Pairing.G1Point memory vk_x = vk.gammaABC[0];
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.pointAdd(vk_x, Pairing.pointMul(vk.gammaABC[i + 1], input[i]));

         
        return Pairing.pairingProd4(
            proof.A, proof.B,
            vk_x.negate(), vk.gamma,
            proof.C.negate(), vk.delta,
            vk.alpha.negate(), vk.beta);
    }
}

library MiMC
{
    function getScalarField ()
        internal pure returns (uint256)
    {
        return 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    }

     
    function MiMCpe7( uint256 in_x, uint256 in_k, uint256 in_seed, uint256 round_count )
        internal pure returns(uint256 out_x)
    {
        assembly {
            if lt(round_count, 1) { revert(0, 0) }

             
            let c := mload(0x40)
            mstore(0x40, add(c, 32))
            mstore(c, in_seed)

            let localQ := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            let t
            let a

             
            for { let i := round_count } gt(i, 0) { i := sub(i, 1) } {
                 
                mstore(c, keccak256(c, 32))

                 
                t := addmod(addmod(in_x, mload(c), localQ), in_k, localQ)               
                a := mulmod(t, t, localQ)                                               
                in_x := mulmod(mulmod(a, mulmod(a, a, localQ), localQ), t, localQ)      
            }

             
            out_x := addmod(in_x, in_k, localQ)
        }
    }
       
    function MiMCpe7_mp( uint256[] memory in_x, uint256 in_k, uint256 in_seed, uint256 round_count )
        internal pure returns (uint256)
    {
        uint256 r = in_k;
        uint256 localQ = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

        for( uint256 i = 0; i < in_x.length; i++ )
        {
            r = (r + in_x[i] + MiMCpe7(in_x[i], r, in_seed, round_count)) % localQ;
        }

         
         
         
         
         
         
         
         
         
         
        
        return r;
    }

    function Hash( uint256[] memory in_msgs, uint256 in_key )
        internal pure returns (uint256)
    {
        return MiMCpe7_mp(in_msgs, in_key, uint256(keccak256("mimc")), 91);
    }

    function Hash( uint256[] memory in_msgs )
        internal pure returns (uint256)
    {
        return Hash(in_msgs, 0);
    }
}

library MerkleTree
{
     
    uint constant internal TREE_DEPTH = 15;


     
    uint constant internal MAX_LEAF_COUNT = 32768;


    struct Data
    {
        uint cur;
        uint256[32768][16] nodes;  
    }

    function treeDepth() internal pure returns (uint256) {
        return TREE_DEPTH;
    }


    function fillLevelIVs (uint256[15] memory IVs)
        internal
        pure
    {
        IVs[0] = 149674538925118052205057075966660054952481571156186698930522557832224430770;
        IVs[1] = 9670701465464311903249220692483401938888498641874948577387207195814981706974;
        IVs[2] = 18318710344500308168304415114839554107298291987930233567781901093928276468271;
        IVs[3] = 6597209388525824933845812104623007130464197923269180086306970975123437805179;
        IVs[4] = 21720956803147356712695575768577036859892220417043839172295094119877855004262;
        IVs[5] = 10330261616520855230513677034606076056972336573153777401182178891807369896722;
        IVs[6] = 17466547730316258748333298168566143799241073466140136663575045164199607937939;
        IVs[7] = 18881017304615283094648494495339883533502299318365959655029893746755475886610;
        IVs[8] = 21580915712563378725413940003372103925756594604076607277692074507345076595494;
        IVs[9] = 12316305934357579015754723412431647910012873427291630993042374701002287130550;
        IVs[10] = 18905410889238873726515380969411495891004493295170115920825550288019118582494;
        IVs[11] = 12819107342879320352602391015489840916114959026915005817918724958237245903353;
        IVs[12] = 8245796392944118634696709403074300923517437202166861682117022548371601758802;
        IVs[13] = 16953062784314687781686527153155644849196472783922227794465158787843281909585;
        IVs[14] = 19346880451250915556764413197424554385509847473349107460608536657852472800734;
    }


    function hashImpl (uint256 left, uint256 right, uint256 IV)
        internal
        pure
        returns (uint256)
    {
        uint256[] memory x = new uint256[](2);
        x[0] = left;
        x[1] = right;

        return MiMC.Hash(x, IV);
    }


    function insert(Data storage self, uint256 leaf)
        internal
        returns (uint256 new_root, uint256 offset)
    {
        require(leaf != 0);


        uint256[15] memory IVs;
        fillLevelIVs(IVs);

        offset = self.cur;

        require(offset != MAX_LEAF_COUNT - 1);

        self.nodes[0][offset] = leaf;

        new_root = updateTree(self, IVs);

        self.cur = offset + 1;
    }


     
    function verifyPath(uint256 leaf, uint256[15] memory in_path, bool[15] memory address_bits)
        internal 
        pure 
        returns (uint256 merkleRoot)
    {
        uint256[15] memory IVs;
        fillLevelIVs(IVs);

        merkleRoot = leaf;

        for (uint depth = 0; depth < TREE_DEPTH; depth++) {
            if (address_bits[depth]) {
                merkleRoot = hashImpl(in_path[depth], merkleRoot, IVs[depth]);
            } else {
                merkleRoot = hashImpl(merkleRoot, in_path[depth], IVs[depth]);
            }
        }
    }


    function verifyPath(Data storage self, uint256 leaf, uint256[15] memory in_path, bool[15] memory address_bits)
        internal 
        view 
        returns (bool)
    {
        return verifyPath(leaf, in_path, address_bits) == getRoot(self);
    }


    function getLeaf(Data storage self, uint depth, uint offset)
        internal
        view
        returns (uint256)
    {
        return getUniqueLeaf(depth, offset, self.nodes[depth][offset]);
    }


    function getMerkleProof(Data storage self, uint index)
        internal
        view
        returns (uint256[15] memory proof_path)
    {
        for (uint depth = 0; depth < TREE_DEPTH; depth++)
        {
            if (index % 2 == 0) {
                proof_path[depth] = getLeaf(self, depth, index + 1);
            } else {
                proof_path[depth] = getLeaf(self, depth, index - 1);
            }
            index = uint(index / 2);
        }
    }


    function getUniqueLeaf(uint256 depth, uint256 offset, uint256 leaf)
        internal pure returns (uint256)
    {
        if (leaf == 0x0)
        {
            leaf = uint256(
                sha256(
                    abi.encodePacked(
                        uint16(depth),
                        uint240(offset)))) % MiMC.getScalarField();
        }

        return leaf;
    }


    function updateTree(Data storage self, uint256[15] memory IVs)
        internal returns(uint256 root)
    {
        uint currentIndex = self.cur;
        uint256 leaf1;
        uint256 leaf2;

        for (uint depth = 0; depth < TREE_DEPTH; depth++)
        {

            if (currentIndex%2 == 0)
            {
                leaf1 = self.nodes[depth][currentIndex];

                leaf2 = getUniqueLeaf(depth, currentIndex + 1, self.nodes[depth][currentIndex + 1]);
            } else
            {
                leaf1 = getUniqueLeaf(depth, currentIndex - 1, self.nodes[depth][currentIndex - 1]);

                leaf2 = self.nodes[depth][currentIndex];
            }

            uint nextIndex = uint(currentIndex/2);

            self.nodes[depth+1][nextIndex] = hashImpl(leaf1, leaf2, IVs[depth]);

            currentIndex = nextIndex;
        }

        return self.nodes[TREE_DEPTH][0];
    }


    function getRoot (Data storage self)
        internal
        view
        returns (uint256)
    {
        return self.nodes[TREE_DEPTH][0];
    }

    function getNextLeafIndex (Data storage self)
        internal
        view
        returns (uint256)
    {
        return self.cur;
    }
}


contract Mixer
{
    using MerkleTree for MerkleTree.Data;

    uint constant public AMOUNT = 1 ether;

    uint256[14] vk;
    uint256[] gammaABC;

    mapping (uint256 => bool) public nullifiers;
    mapping (address => uint256[]) public pendingDeposits;

    MerkleTree.Data internal tree;

    event CommitmentAdded(address indexed _fundingWallet, uint256 _leaf);
    event LeafAdded(uint256 _leaf, uint256 _leafIndex);

    constructor(uint256[14] memory in_vk, uint256[] memory in_gammaABC)
        public
    {
        vk = in_vk;
        gammaABC = in_gammaABC;
    }

    function getRoot()
        public
        view
        returns (uint256)
    {
        return tree.getRoot();
    }

     
    function commit(uint256 leaf, address fundingWallet)
        public
        payable
    {
        require(leaf > 0, "null leaf");
        pendingDeposits[fundingWallet].push(leaf);
        emit CommitmentAdded(fundingWallet, leaf);
        if (msg.value > 0) fundCommitment();
    }

    function fundCommitment() private {
        require(msg.value == AMOUNT, "wrong value");
        uint256[] storage leaves = pendingDeposits[msg.sender];
        require(leaves.length > 0, "commitment must be sent first");
        uint256 leaf = leaves[leaves.length - 1];
        leaves.length--;
        (, uint256 leafIndex) = tree.insert(leaf);
        emit LeafAdded(leaf, leafIndex);
    }

     
    function () external payable {
        fundCommitment();
    }

    function makeLeafHash(uint256 nullifier_secret, address wallet_address)
        external
        pure
        returns (uint256)
    {
        bytes32 digest = sha256(abi.encodePacked(nullifier_secret, uint256(wallet_address)));
        uint256 mask = uint256(-1) >> 4;  
        return uint256(digest) & mask;
    }

    function makeNullifierHash(uint256 nullifier_secret)
        external
        pure
        returns (uint256)
    {
        uint256[] memory vals = new uint256[](2);
        vals[0] = nullifier_secret;
        vals[1] = nullifier_secret;
        return MiMC.Hash(vals, 0);
    }

    function getMerklePath(uint256 leafIndex)
        external
        view
        returns (uint256[15] memory out_path)
    {
        out_path = tree.getMerkleProof(leafIndex);
    }

    function isSpent(uint256 nullifier)
        public
        view
        returns (bool)
    {
        return nullifiers[nullifier];
    }

    function verifyProof(uint256 in_root, address in_wallet_address, uint256 in_nullifier, uint256[8] memory proof)
        public
        view
        returns (bool)
    {
        uint256[] memory snark_input = new uint256[](3);
        snark_input[0] = in_root;
        snark_input[1] = uint256(in_wallet_address);
        snark_input[2] = in_nullifier;

        return Verifier.verify(vk, gammaABC, proof, snark_input);
    }

    function withdraw(
        address payable in_withdraw_address,
        uint256 in_nullifier,
        uint256[8] memory proof
    )
        public
    {
        uint startGas = gasleft();
        require(!nullifiers[in_nullifier], "Nullifier used");
        require(verifyProof(getRoot(), in_withdraw_address, in_nullifier, proof), "Proof verification failed");

        nullifiers[in_nullifier] = true;

        uint gasUsed = startGas - gasleft() + 82775;
        uint relayerRefund = gasUsed * tx.gasprice;
        if(relayerRefund > AMOUNT/20) relayerRefund = AMOUNT/20;
        in_withdraw_address.transfer(AMOUNT - relayerRefund);  
        msg.sender.transfer(relayerRefund);  
    }

    function treeDepth() external pure returns (uint256) {
        return MerkleTree.treeDepth();
    }

    function getNextLeafIndex() external view returns (uint256) {
        return tree.getNextLeafIndex();
    }
}