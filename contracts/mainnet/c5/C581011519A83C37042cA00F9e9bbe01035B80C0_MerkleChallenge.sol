// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./MerkleDistributor.sol";

contract Token is ERC20Like {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1_000_000 ether;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender) {
            allowance[from][to] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MerkleChallenge {
    // challenger => merkleDistributor contract
    mapping(address => address) public merkleDistributorMap;
    mapping(address => bool) public challenged;

    modifier onlyChallenger() {
        require(merkleDistributorMap[msg.sender] != address(0), "only challenger");
        require(!challenged[msg.sender], "already challenged");
        _;
    }

    receive() external payable {}

    function register() external {
        require(merkleDistributorMap[msg.sender] == address(0), "already registered");

        Token token = new Token();
        uint256 airdropAmount = 75000 * 10 ** 18;

        MerkleDistributor merkleDistributor = new MerkleDistributor(
            address(token),
            bytes32(0x5176d84267cd453dad23d8f698d704fc7b7ee6283b5131cb3de77e58eb9c3ec3)
        );
        token.transfer(address(merkleDistributor), airdropAmount);
        merkleDistributorMap[msg.sender] = address(merkleDistributor);
    }

    function withdraw() external onlyChallenger {
        require(isSolved(merkleDistributorMap[msg.sender]), "not solved");
        payable(msg.sender).transfer(0.1 ether);
        challenged[msg.sender] = true;
    }

    function isSolved(address _merkleDistributor) public view returns (bool) {
        Token _token = Token(MerkleDistributor(_merkleDistributor).token());
        bool condition1 = _token.balanceOf(_merkleDistributor) == 0;
        bool condition2 = false;
        for (uint256 i = 0; i < 64; ++i) {
            if (!MerkleDistributor(_merkleDistributor).isClaimed(i)) {
                condition2 = true;
                break;
            }
        }
        return condition1 && condition2;
    }
}

// SPDX-License-Identifier: UNLICENSED

/*
// full merkle tree:

{
    "merkleRoot": "0x5176d84267cd453dad23d8f698d704fc7b7ee6283b5131cb3de77e58eb9c3ec3",
    "tokenTotal": "0x0fe1c215e8f838e00000",
    "claims": {
        "0x00E21E550021Af51258060A0E18148e36607C9df": {
            "index": 0,
            "amount": "0x09906894166afcc878",
            "proof": [
                "0xa37b8b0377c63d3582581c28a09c10284a03a6c4185dfa5c29e20dbce1a1427a",
                "0x0ae01ec0f7a50774e0c1ad35f0f5efcc14c376f675704a6212b483bfbf742a69",
                "0x3f267b524a6acda73b1d3e54777f40b188c66a14a090cd142a7ec48b13422298",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x046887213a87DC19e843E6E3e47Fc3243A129ad0": {
            "index": 1,
            "amount": "0x41563bf77450fa5076",
            "proof": [
                "0xbadd8fe5b50451d4c1157443afb33e60369d0949d65fc61d06fca35576f68caa",
                "0xb74970b484c464c0e6872c78a4fec81a5166f500c6e128052ca5db7a7e22d858",
                "0xf5f6b74e51a15573007b59fb217c22c55fd9748a1e70578c6ddaf550b7298882",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x04E9df03e12F21bFB77a97e4306Ef4daeb4129c2": {
            "index": 2,
            "amount": "0x36df43795a7caf4540",
            "proof": [
                "0x30976e6e39aeda0af50595309cfe319061ee99610d640a3ff2d490653963d22a",
                "0xc8a963490279786bf4d9522dad319dd536d7de4764d2fc6564356ff73b49cf16",
                "0x955c47a5eea3ebf139056c0603d096a40a686b2304506f7509859fe9cc19bd79",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x05e1E52D41A616Df68810039AD972D6f1280cbae": {
            "index": 3,
            "amount": "0x195efe9af09f01e4b6",
            "proof": [
                "0x28b36a3afabfcfd4a6bc37d9275ebc12768dead832b45fe0f798666b3504b761",
                "0xb78206103b20c68f5d201d54f68a9ae27530ce21120501797e6cf8c69f6f2be2",
                "0x955c47a5eea3ebf139056c0603d096a40a686b2304506f7509859fe9cc19bd79",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x0b3041F7d5E847b06CbE83d096f65b3C19869B39": {
            "index": 4,
            "amount": "0x4dfdb4bae7d0d20cb6",
            "proof": [
                "0xe13771d2a0c4dea1be80f66f0a2c74f429151e8146d642c4306be93190bc89c5",
                "0xd5423e8e964fcfbe8025bf3f96273ba0c0039f284d40c720a8466bd39e5d3eb9",
                "0x2fa599012c0491428e6451d1cc1511f133f82c66ee98b9eefc1b4c263db48518",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x20ECC9f3Dfa1E4CF967F6CCb96087603Cd0C0ea5": {
            "index": 5,
            "amount": "0x3b700f748237270c9f",
            "proof": [
                "0x25342959be7576258fb48037698afbc01f7e1d0c391d5039ca70adec577b5a62",
                "0x4db4c30a97febfe168893f90f7ed6b5d2fd442c87de6db7367ca1f4f254d7560",
                "0x0cd186d2b1377ee96a87ef7a295dec75cc05b54a08fcaca61868911d6ac9bc27",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x21300678bcC7E47c9c7fa58eE4F51Ea46aB91140": {
            "index": 6,
            "amount": "0x24f61ca059bc24bfe0",
            "proof": [
                "0x7ff95132a090b7338eb1e2937425f14f7e112cca82de611f0eab14b5310848ec",
                "0xa9fd6f5ade2e4b246e93337936684b7a5cc7285dca4caf3b26203f258211bb75",
                "0x449eac22434639a214604e71bc3c53ee18a2803f1cca16000e5d26fe3ee6ac11",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x21D11058D97A281ceeF9Bdd8A5d2F1Ca5472E630": {
            "index": 7,
            "amount": "0x35ddccf9e44848307f",
            "proof": [
                "0x00827f08f3d161ff8988e9489ef341a194b5d3a36307e79881af5b8cc03ae154",
                "0x68cb43b42c0f1a39502ac222e901a42950ac602e2335eca67a15e3f6a661a7d7",
                "0xd7fc0d5cfae7aea3e6f1c1a6d427c9da67942e8091b8bf719a39cb31442588cf",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x249934e4C5b838F920883a9f3ceC255C0aB3f827": {
            "index": 8,
            "amount": "0xa0d154c64a300ddf85",
            "proof": [
                "0xe10102068cab128ad732ed1a8f53922f78f0acdca6aa82a072e02a77d343be00",
                "0xd779d1890bba630ee282997e511c09575fae6af79d88ae89a7a850a3eb2876b3",
                "0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x24dD3381afaE5d29E8eAf398aa5e9A79E41e8B36": {
            "index": 9,
            "amount": "0x73294a1a5881b324fe",
            "proof": [
                "0x4e5133c9221f862a0116601af29c036030d7a2d6656057ce9a3790751d9380dd",
                "0x26171694d9e478c26b02ca6850ea3b0d94dba9ead9fc33ed3f0cb59482117454",
                "0x54dfc2bcb68496ea7b8f2e6abbbd3dc442151628379a64aa231ce6fb6aae02b6",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x29a53d36964Db6fD54f1121d7D15e9ccD99aD632": {
            "index": 10,
            "amount": "0x195da98a14415c0697",
            "proof": [
                "0xbeba51d0cb0bc6339edf1832ce33515c92b2bfdbf243e531188470ca084b3b2d",
                "0xb74970b484c464c0e6872c78a4fec81a5166f500c6e128052ca5db7a7e22d858",
                "0xf5f6b74e51a15573007b59fb217c22c55fd9748a1e70578c6ddaf550b7298882",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x2a0097816875A110E36cFD07228D6b1bB4c31d76": {
            "index": 11,
            "amount": "0x3b58f426caa31ae7d1",
            "proof": [
                "0x0354af4f2c661dc1e918482f626b66f110408fb709894c9c488a001eb0742399",
                "0xf467876e338a148fd70b2581b6b3a7469047be31dca35c345a510ef85dba31dc",
                "0xd7fc0d5cfae7aea3e6f1c1a6d427c9da67942e8091b8bf719a39cb31442588cf",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x2cC891F5Ab151fD54358b2f793f7D80681FAb5AE": {
            "index": 12,
            "amount": "0x37a7e4700ede0a9511",
            "proof": [
                "0x4e7ffaaa80516282b025bb78de5e2ff37bf537c79efbef7d3a76212520edfa1e",
                "0x570a5dc89eddc4cdb73631b6f43d3e20a10b272a69b0b9087d778502b4ae034b",
                "0xe17532a1de454f0b97005a3608233cbbdf6680bdefb2eab2dade48d76df0407f",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x3600C2789dbA3D3Eb5c36d11d07886c53d2A7eCF": {
            "index": 13,
            "amount": "0x3d0142d7d7218206f9",
            "proof": [
                "0x53af2e862fa1f6e8b669f83b25bfd6d2c3fb52df0ca2d76c03374bffca658b2d",
                "0x570a5dc89eddc4cdb73631b6f43d3e20a10b272a69b0b9087d778502b4ae034b",
                "0xe17532a1de454f0b97005a3608233cbbdf6680bdefb2eab2dade48d76df0407f",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x3869541f32b1c9b3Aff867B1a2448d64b5B8c13b": {
            "index": 14,
            "amount": "0xcda8b311ab8fa262c8",
            "proof": [
                "0x9907e0ad71155513cb3a0fa6fb714b1bbdd5b85005a6cae4f32d68d843bec8b8",
                "0x72828ce11efc964cf1f828f243091a1783032ec9dbe26d53d1ef15beb050508c",
                "0x449eac22434639a214604e71bc3c53ee18a2803f1cca16000e5d26fe3ee6ac11",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x3ACcF55fcE78E5df0E33A0fB198bf885B0194828": {
            "index": 15,
            "amount": "0x283eff6bcf599ad067",
            "proof": [
                "0x65b5391533e6646ac62af8e8d4b2ecb10ccc163fd91ad2309e25299ef0527e6d",
                "0x62663a6d05597df610cb657a9d6691fd7c5352e6ed2f76f0274c3bc96ec14aed",
                "0x9c655dc701fa000048be0b99912551f71b77031ce47437fa220120e8b56a877c",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x3a0bF58A644Ff38F56C79476584394Cf04B2ef72": {
            "index": 16,
            "amount": "0x7cb9abf0e3262da923",
            "proof": [
                "0xad664d58ccd7f0f2c817ae6a1620d88e4602131e17207efdd89f6cf98b903628",
                "0x86f8b4db67c570567b6d8c72a4127cce15ed261863f0fc28c63bfa9e92a8c4fd",
                "0x3f267b524a6acda73b1d3e54777f40b188c66a14a090cd142a7ec48b13422298",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x417D6b3edBE9Ad2444241cc9863573dcDE8bf846": {
            "index": 17,
            "amount": "0x4196852d9dc64be33a",
            "proof": [
                "0xa2f005afe53c681aec101c5107b1bc6619e1ebaea3d55fc38dabac341c958619",
                "0x0c15f6d9f61156109f0005f9b7f675b23e7aec4694ab76571f78c1e967dc99ef",
                "0x41e12276ae416e87527eef564a668374da0157d93387edd75796ffeab88bf849",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x42dd0823B8e43082b122e92b39F972B939ED597a": {
            "index": 18,
            "amount": "0x1b97eb44d92febab98",
            "proof": [
                "0x7b43e82a88f0da5db71bc1c82f1515b9b17ff69e88ec3f101a50cfd98d7f60ce",
                "0x5eeac0a5817d0a92ac8111f5baea4d21a3d9a935bb9a8ab87c326d52fe9dce44",
                "0x6396734133b37a66dcaf6e892db605531ae16ff8945cbccc5590b3624bbda293",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x4B3570C7A1ff2D20F344f4bD1dD499A1e3d5F4fb": {
            "index": 19,
            "amount": "0x7f1616a67585a28802",
            "proof": [
                "0xd43194becc149ad7bf6db88a0ae8a6622e369b3367ba2cc97ba1ea28c407c442",
                "0x8920c10a5317ecff2d0de2150d5d18f01cb53a377f4c29a9656785a22a680d1d",
                "0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x4FeD95B0d2E1F3bD31E3d7FE90A5Bf74Ae991C32": {
            "index": 20,
            "amount": "0x386ffb4b46b6e905c7",
            "proof": [
                "0xb142a5c6b86dd9fdd364b8aef591f47c181dcfbd41cde017eee96c7b8a686e2e",
                "0x86f8b4db67c570567b6d8c72a4127cce15ed261863f0fc28c63bfa9e92a8c4fd",
                "0x3f267b524a6acda73b1d3e54777f40b188c66a14a090cd142a7ec48b13422298",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x51E932b7556f95cf70F9d87968184205530b83A5": {
            "index": 21,
            "amount": "0x42ab44de8b807cbc4f",
            "proof": [
                "0x59b5a9cd883510d6863a0715c88a98b079c036a4fb5039a0105ed4b21f3658c5",
                "0x8d95f5b0ee482a4d1f61599c5b35b324a89036b657998b1def0dde35a92123aa",
                "0xe17532a1de454f0b97005a3608233cbbdf6680bdefb2eab2dade48d76df0407f",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x58F3fd7DD3EFBBF05f1cd40862ee562f5C1a4089": {
            "index": 22,
            "amount": "0x2d1a8654a3b98df3d1",
            "proof": [
                "0x164465e87b253a734a56bc34e3f4b5f24c5f3ee5cade2a6ca2f8f48535309c95",
                "0x6353fdd25845769b10a6f4e18d04c0a1226d47381aa51bfcb971395733433879",
                "0x0cd186d2b1377ee96a87ef7a295dec75cc05b54a08fcaca61868911d6ac9bc27",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x5C2DE342003b038E81a9E5aa8286dCB7A30DCE94": {
            "index": 23,
            "amount": "0x0985fd6041e59eebbb",
            "proof": [
                "0xf552c4b0909600d226d5f42161c58f7a5722027298f8c204247323336262be88",
                "0xb237516aa3fae34a6ca09a662b8457ffb22dd2dfc5aa144e0d6c0f2445821b86",
                "0x2fa599012c0491428e6451d1cc1511f133f82c66ee98b9eefc1b4c263db48518",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x61300D372cfa25E34E5667B45199801FF3f4B3D9": {
            "index": 24,
            "amount": "0x38b5b63d5f211c5a71",
            "proof": [
                "0xfb6d302655b6f6a8f6f1aca20a3edb8c6c8c4640daab78796f3e1c0cd0ec8606",
                "0xb237516aa3fae34a6ca09a662b8457ffb22dd2dfc5aa144e0d6c0f2445821b86",
                "0x2fa599012c0491428e6451d1cc1511f133f82c66ee98b9eefc1b4c263db48518",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x6A4CEBddA50C4480f8772834720dCDCB01CaFb5D": {
            "index": 25,
            "amount": "0x5d1b4cb3431ecb4f1a",
            "proof": [
                "0x763326fbee252000fc15343ef2cc074ab3414dbc8e35312781451927dce56f80",
                "0x644ff4aa4c4a5713d7d2189eaf1d60cc99a4924db146f3714d998510f35ed34c",
                "0x4651c9cafba7a07e593d2fddecb28bfd6af2c0731126931e60a621684363524a",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x6D26E7739C90230349F4F6e8DAF8da8188e2c5cD": {
            "index": 26,
            "amount": "0x33d68b2ef4c9c4e1ee",
            "proof": [
                "0xd2b8ed2291e92e504017d646568210a107890c34d22aed283cb1a77d1ff66b9d",
                "0x225de26d438b50d8afea1120376d92b188d770338d4629a6cfbd09c7af39d34c",
                "0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x6b3D0be96d4dD163dCADF6a6bc71EBb8dD42a9B2": {
            "index": 27,
            "amount": "0x55cb74d295a7078628",
            "proof": [
                "0x42545b56127a9fe8daea5c3cf4036a47cf91f4596b49a70be6e5f807c592a561",
                "0x25e8e051b1e50b71a99e6247bef8c6566c3ec41d3ba014d5963fc31b48169965",
                "0x54dfc2bcb68496ea7b8f2e6abbbd3dc442151628379a64aa231ce6fb6aae02b6",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x767911D2c042332F6b2007E86f1DdA2B674F6185": {
            "index": 28,
            "amount": "0x2fb5d437c8cd9dfc7f",
            "proof": [
                "0x7216025ef8f0d72ddac0c434ac52525b6946623534ec3cbe5ea1317c27ad7a9a",
                "0x43047705e643f244c1fa91232f837793bd978d50a148cccdcb5883cd20d21f07",
                "0x4651c9cafba7a07e593d2fddecb28bfd6af2c0731126931e60a621684363524a",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x793652bf3D5Dc52b92fc3131C27D9Ce82890422D": {
            "index": 29,
            "amount": "0x2609c108e379ee4aad",
            "proof": [
                "0x565be7f9f28d9025dba7935e9251d55c9cb6bc8198366d4b99aa072229e015f9",
                "0x8d95f5b0ee482a4d1f61599c5b35b324a89036b657998b1def0dde35a92123aa",
                "0xe17532a1de454f0b97005a3608233cbbdf6680bdefb2eab2dade48d76df0407f",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x7B237D20D18f1872b006D924FA2Aa4f60104A296": {
            "index": 30,
            "amount": "0x304e03adc3e62a2d09",
            "proof": [
                "0x7c6732545262910be97f294b94dfe4a16612869a1e167184895d72b316f10717",
                "0x5eeac0a5817d0a92ac8111f5baea4d21a3d9a935bb9a8ab87c326d52fe9dce44",
                "0x6396734133b37a66dcaf6e892db605531ae16ff8945cbccc5590b3624bbda293",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x7cD932afCaF03fA09FdfCFF35A5a7D4b6b4F479e": {
            "index": 31,
            "amount": "0x41bc0955cae5406c53",
            "proof": [
                "0x7c8901ce6a2988d1b59e96b346a1da117f0360266f2357a2b35e42de68d67b62",
                "0x3c7a509d9a786d3476cf62d5076e246cdc15572aadfbfc49993290bea04dc33e",
                "0x6396734133b37a66dcaf6e892db605531ae16ff8945cbccc5590b3624bbda293",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x7cbB03Eaccc122eF9e90eD99e5646Fc9B307bcd8": {
            "index": 32,
            "amount": "0x09906894166b087772",
            "proof": [
                "0xd6948c2c22e5c79cf7aa1dcce8e6927388d7c650445159b9e272f84c95a032e6",
                "0x19e39d26bfd282e8e58964c4d9e4bc060308166347034e432d8a9fbefb2c6e68",
                "0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x8250D918318e4b2B456882D26806bE4270F4b82B": {
            "index": 33,
            "amount": "0x38addb61463edc4bc6",
            "proof": [
                "0x8652a5d44578e32b80888eba7b90d776d65f946d28c2a92a174c28061eb19470",
                "0xa9fd6f5ade2e4b246e93337936684b7a5cc7285dca4caf3b26203f258211bb75",
                "0x449eac22434639a214604e71bc3c53ee18a2803f1cca16000e5d26fe3ee6ac11",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x860Faad971d0e48B96D69C21A32Ca288229449c4": {
            "index": 34,
            "amount": "0x13ea41317f589a9e0c",
            "proof": [
                "0x115e62dc3725c12935896f44553d0835473aa466efc65b46dc70749bb69655bc",
                "0xb1408b0fc0b96c6469dd721ebd1c04ec436da2e819765a758fe2f17c9fbf6021",
                "0x292ea2e708cd883538e918fa5e092fe233fc7ef4be50902e9c63610af22ba9b8",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x88127EF65888a2c4324747DC85aD20b355D3effb": {
            "index": 35,
            "amount": "0x32cb97226798201629",
            "proof": [
                "0x019c868fa8ed0a5d4d0c902c5bd7b18a53b75b0575e8b8bea70041af9310949f",
                "0x68cb43b42c0f1a39502ac222e901a42950ac602e2335eca67a15e3f6a661a7d7",
                "0xd7fc0d5cfae7aea3e6f1c1a6d427c9da67942e8091b8bf719a39cb31442588cf",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x8Ce478613DE9E8ff5643D3CfE0a82a7C232453E6": {
            "index": 36,
            "amount": "0x828f60c1e44867745f",
            "proof": [
                "0xc75df667b1e0673d6434808d3e4466c39f61a00b113663a58cfdbfc7ccef29e3",
                "0x83f60a763e672b25703da0229e530c207933554cc4c26dfe30d69b11a2f5e511",
                "0xf5f6b74e51a15573007b59fb217c22c55fd9748a1e70578c6ddaf550b7298882",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x8a85e6D0d2d6b8cBCb27E724F14A97AeB7cC1f5e": {
            "index": 37,
            "amount": "0x5dacf28c4e17721edb",
            "proof": [
                "0xd48451c19959e2d9bd4e620fbe88aa5f6f7ea72a00000f40f0c122ae08d2207b",
                "0x8920c10a5317ecff2d0de2150d5d18f01cb53a377f4c29a9656785a22a680d1d",
                "0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x8ff0687af6f88C659d80D2e3D97B0860dbaB462e": {
            "index": 38,
            "amount": "0x391da2eb282a38e702",
            "proof": [
                "0xa0043ed2863bf56a6190c105922498904db3844dad729b3f5d9c6944a5dd987c",
                "0xd29a8264fe1886a31674e30d34a918354022351498a0f42f68f12e0ca2fb3a09",
                "0x41e12276ae416e87527eef564a668374da0157d93387edd75796ffeab88bf849",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0x959DB5c6843304F9F6290f6c7199DD9364ec419D": {
            "index": 39,
            "amount": "0x33310207c285e55392",
            "proof": [
                "0x5a53412f6ed9a29d5c57527fa3d9c32d774387a3994db9f61849cdcb189a2a4c",
                "0x9fb9f6ee8f0b83a0f1eb41e57eb1b4a53d0dfa86bab2bb38093113670cf2d94c",
                "0x9c655dc701fa000048be0b99912551f71b77031ce47437fa220120e8b56a877c",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x97D10d05275e263F46E9eA21c9aE62507eBB65e3": {
            "index": 40,
            "amount": "0x1969ca1f270d7cd9d1",
            "proof": [
                "0x2bb44cee53daf66acb6f397831fc2d678c84b5b09ca7b1fff7afda9bb75ef05e",
                "0xb78206103b20c68f5d201d54f68a9ae27530ce21120501797e6cf8c69f6f2be2",
                "0x955c47a5eea3ebf139056c0603d096a40a686b2304506f7509859fe9cc19bd79",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0x9B34e16b3D298790D61c4F460b616c91740A4a1a": {
            "index": 41,
            "amount": "0x3678ab48c78fe81be3",
            "proof": [
                "0x0701f8f739a2fec08a0e04cc1c3e66fa558dba855236882c5a624d0cea9a4e0b",
                "0xf467876e338a148fd70b2581b6b3a7469047be31dca35c345a510ef85dba31dc",
                "0xd7fc0d5cfae7aea3e6f1c1a6d427c9da67942e8091b8bf719a39cb31442588cf",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xA8cAb79bedA626E2c3c2530AC3e11fc259F237D6": {
            "index": 42,
            "amount": "0x2db4445d44fddb00d2",
            "proof": [
                "0x15320e37bd46719b860b97998a11ffb42ff26db76ead7e0c43c22e17806502df",
                "0x6353fdd25845769b10a6f4e18d04c0a1226d47381aa51bfcb971395733433879",
                "0x0cd186d2b1377ee96a87ef7a295dec75cc05b54a08fcaca61868911d6ac9bc27",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xA8f416E298066cb578e4377BeFbdb9C08C6252A8": {
            "index": 43,
            "amount": "0x29e0cb8068d84a987b",
            "proof": [
                "0x72c98c344d8b36b7c169dc9d3ea7e43f6927b605aa869fe5fd76dc606edd283b",
                "0x644ff4aa4c4a5713d7d2189eaf1d60cc99a4924db146f3714d998510f35ed34c",
                "0x4651c9cafba7a07e593d2fddecb28bfd6af2c0731126931e60a621684363524a",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xB58Ad39c58Bdf1F4E62466409c44265A89623722": {
            "index": 44,
            "amount": "0x7347e43564a789c880",
            "proof": [
                "0x095fc5ae9321eabfede2c4fac05af6ae866f315c08b4f60a3d1b5c166de660ed",
                "0x1577bdc1958b6677f9e850bbb2b938daa51979ce9af4b0dbcc7f763c3aee1ee3",
                "0x292ea2e708cd883538e918fa5e092fe233fc7ef4be50902e9c63610af22ba9b8",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xC379f96dcdF68A5FA3722456fB4614647D1c6bbD": {
            "index": 45,
            "amount": "0x8202b24cb5d34efa49",
            "proof": [
                "0x635d83d54c68be93dbb2d55213899ce15315a8052c5fa76b01d2cafc63b1ec16",
                "0x9fb9f6ee8f0b83a0f1eb41e57eb1b4a53d0dfa86bab2bb38093113670cf2d94c",
                "0x9c655dc701fa000048be0b99912551f71b77031ce47437fa220120e8b56a877c",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xC7FA2a8D3b433C9BfCdd93941195e2C5495EaE51": {
            "index": 46,
            "amount": "0x566498ec48a13dd013",
            "proof": [
                "0x4cb280a759741642be3f25ac989578797e1d1295d348755bc71d12890f4e1a06",
                "0x26171694d9e478c26b02ca6850ea3b0d94dba9ead9fc33ed3f0cb59482117454",
                "0x54dfc2bcb68496ea7b8f2e6abbbd3dc442151628379a64aa231ce6fb6aae02b6",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xC7af0Df0B605e4072D85BECf5fb06acF40f88db9": {
            "index": 47,
            "amount": "0x2c15bae170d80220aa",
            "proof": [
                "0xa18d9178bab44c66a0ec909913a9168fb57675f96be4dc78e5bd5c3d62bdf585",
                "0x0c15f6d9f61156109f0005f9b7f675b23e7aec4694ab76571f78c1e967dc99ef",
                "0x41e12276ae416e87527eef564a668374da0157d93387edd75796ffeab88bf849",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xCd19f5E3e4eb7507bB3557173c5aE5021407Aa25": {
            "index": 48,
            "amount": "0x5f0652b88c2c085aea",
            "proof": [
                "0x0f7a6dbdb4f6108c52ea0b0083cba2bc48eb7c0732b2909ba4e06f5c43d95d52",
                "0xb1408b0fc0b96c6469dd721ebd1c04ec436da2e819765a758fe2f17c9fbf6021",
                "0x292ea2e708cd883538e918fa5e092fe233fc7ef4be50902e9c63610af22ba9b8",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xCdBf68C24f9dBA3735Fc79623BaAdbB0Ca152093": {
            "index": 49,
            "amount": "0x25b42c67c4ec6c225d",
            "proof": [
                "0xd0387293a05c1b496ebb8671e1490cf3032c5d22617f616e99189f6dfc698507",
                "0x225de26d438b50d8afea1120376d92b188d770338d4629a6cfbd09c7af39d34c",
                "0xc999b0a9763c737361256ccc81801b6f759e725e115e4a10aa07e63d27033fde",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xE3fB01b0A4e48CE757BfD801002caC627f6064c0": {
            "index": 50,
            "amount": "0x2c756cdfe2f4d763bc",
            "proof": [
                "0x7ed7078322373dc76f5fd327fe18d63e1fd9811c162527711a2523a79595d383",
                "0x3c7a509d9a786d3476cf62d5076e246cdc15572aadfbfc49993290bea04dc33e",
                "0x6396734133b37a66dcaf6e892db605531ae16ff8945cbccc5590b3624bbda293",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xE59820351B7F93ba9dFfA3483741b4266280fcA4": {
            "index": 51,
            "amount": "0x2c69e7f2c5c1fb4d09",
            "proof": [
                "0xdae406929d3fb1a4f6b11c05a71ca6a8c86ad99c770abcbf5eb98a5fa0447734",
                "0x19e39d26bfd282e8e58964c4d9e4bc060308166347034e432d8a9fbefb2c6e68",
                "0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xED43214BB831Bb1543566A52B230919D7C74ae7C": {
            "index": 52,
            "amount": "0x153309c1e553fcfa4a",
            "proof": [
                "0x098a4ebeaea5dcab6543f613d606a459b71211773fdd3f71a91be667c78cb445",
                "0x1577bdc1958b6677f9e850bbb2b938daa51979ce9af4b0dbcc7f763c3aee1ee3",
                "0x292ea2e708cd883538e918fa5e092fe233fc7ef4be50902e9c63610af22ba9b8",
                "0x51f609195fe7b01dbe09b4f0c130c652183a94ce57e75ba6ead0fc94d2c4f557",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xF5bfA5e1BdAF33df1D5b0e2674a241665c921444": {
            "index": 53,
            "amount": "0x322180f225fed4b65d",
            "proof": [
                "0x25e8db86fed4ac88814814f013f23c2356f1e0960ecd26fddd1614de5fa066af",
                "0x4db4c30a97febfe168893f90f7ed6b5d2fd442c87de6db7367ca1f4f254d7560",
                "0x0cd186d2b1377ee96a87ef7a295dec75cc05b54a08fcaca61868911d6ac9bc27",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xa09674De22A3dD515164FCB777dc223791fB91DE": {
            "index": 54,
            "amount": "0xac7b6f0812eb26f548",
            "proof": [
                "0x9c3fd7a427a178d8c3b3884bb706cc850287c4288d2e065be739b0e908e93fef",
                "0xd29a8264fe1886a31674e30d34a918354022351498a0f42f68f12e0ca2fb3a09",
                "0x41e12276ae416e87527eef564a668374da0157d93387edd75796ffeab88bf849",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xb71D03A0cD1c285c9C32B9992d7b94E37F5E5b5d": {
            "index": 55,
            "amount": "0x2c5e74f5070dac75d9",
            "proof": [
                "0xdb13455978d0488dcb105492f8ea54142f9d500a89bf049bcf00b7fe4c5bdcca",
                "0xd779d1890bba630ee282997e511c09575fae6af79d88ae89a7a850a3eb2876b3",
                "0x46b46a28fab615ab202ace89e215576e28ed0ee55f5f6b5e36d7ce9b0d1feda2",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xb9e1bAD69aebc28E8ba5A20701A35185Ff23A4fA": {
            "index": 56,
            "amount": "0x217f2bf08b80310c45",
            "proof": [
                "0xeab835a5226ecd7bb468ab6f2a12db05290e3bc52a5009f85df966d12909d159",
                "0xd5423e8e964fcfbe8025bf3f96273ba0c0039f284d40c720a8466bd39e5d3eb9",
                "0x2fa599012c0491428e6451d1cc1511f133f82c66ee98b9eefc1b4c263db48518",
                "0xabde46c0e277501c050793f072f0759904f6b2b8e94023efb7fc9112f366374a",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xbE7Df9554c5746fa31Bb2CD7B9CA9b89ac733d7C": {
            "index": 57,
            "amount": "0x14d55d92753f57b739",
            "proof": [
                "0x72000c14174c21b921370d96ba77e711b2e28242f94c8468cf83c30e675da3fb",
                "0x43047705e643f244c1fa91232f837793bd978d50a148cccdcb5883cd20d21f07",
                "0x4651c9cafba7a07e593d2fddecb28bfd6af2c0731126931e60a621684363524a",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xcee18609823ac7c71951fe05206C9924722372A6": {
            "index": 58,
            "amount": "0x3dfa72c4c7dd942165",
            "proof": [
                "0xa9e8f0fbf0d2911d746500a7786606d3fc80abb68a05f77fb730ded04a951c2d",
                "0x0ae01ec0f7a50774e0c1ad35f0f5efcc14c376f675704a6212b483bfbf742a69",
                "0x3f267b524a6acda73b1d3e54777f40b188c66a14a090cd142a7ec48b13422298",
                "0xe2eae0dabf8d82b313729f55298625b7ac9ba0f12e408529bae4a2ce405e7d5f",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xcf67D2C5D6387093E7DE9F0E28D91473E0088E6e": {
            "index": 59,
            "amount": "0x24b00cf419002103ad",
            "proof": [
                "0x6bb0194ee897ebcf7a41ccebee579ab0fe0e191d9e5e9b5815ea2bf8de4c8495",
                "0x62663a6d05597df610cb657a9d6691fd7c5352e6ed2f76f0274c3bc96ec14aed",
                "0x9c655dc701fa000048be0b99912551f71b77031ce47437fa220120e8b56a877c",
                "0x36023974ab0ea95508c311d9ccbf32b662b1ffdb2823817d746f8222ec2dd07c",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xe145dBbEFDD4EEf0ED39195f2Ec75FBB8e55609F": {
            "index": 60,
            "amount": "0x55123165db2ae9a1a2",
            "proof": [
                "0xc54d1feb79a340c603744a595a63cc1e121980ff876c288eaeb67a7c58cb1d12",
                "0x83f60a763e672b25703da0229e530c207933554cc4c26dfe30d69b11a2f5e511",
                "0xf5f6b74e51a15573007b59fb217c22c55fd9748a1e70578c6ddaf550b7298882",
                "0x842f0da95edb7b8dca299f71c33d4e4ecbb37c2301220f6e17eef76c5f386813",
                "0x0e3089bffdef8d325761bd4711d7c59b18553f14d84116aecb9098bba3c0a20c",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xe333ed021E58eF3a3219D43d304fc331e5E287bb": {
            "index": 61,
            "amount": "0x2f36bb4329b1d502e3",
            "proof": [
                "0x385fe12b0ed97da4970945f46d476ade4f8ec725b58b3440304714681d39cfe8",
                "0x25e8e051b1e50b71a99e6247bef8c6566c3ec41d3ba014d5963fc31b48169965",
                "0x54dfc2bcb68496ea7b8f2e6abbbd3dc442151628379a64aa231ce6fb6aae02b6",
                "0xe3affea7b3ec31efa680e4f2728e46392eea685ce2ca5803848a3637de650e13",
                "0x5ccf0ef336c96ea89a6a1b0fa449644f646e67fdf1099608f560fcf8b55118e8",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        },
        "0xe629559bF328BdA47c528849A31e841A0afFF1c7": {
            "index": 62,
            "amount": "0x248a1b23ff3e32491b",
            "proof": [
                "0x99ac0dc09380e26dabe05f039a3d36fbc562b612f40ada5d1707be5246663800",
                "0x72828ce11efc964cf1f828f243091a1783032ec9dbe26d53d1ef15beb050508c",
                "0x449eac22434639a214604e71bc3c53ee18a2803f1cca16000e5d26fe3ee6ac11",
                "0xf2511a8dc138320a73ce3b126adfa94a3e290691a9071d85189d01ef860bd734",
                "0x01cf774c22de70195c31bde82dc3ec94807e4e4e01a42aca6d5adccafe09510e",
                "0x5271d2d8f9a3cc8d6fd02bfb11720e1c518a3bb08e7110d6bf7558764a8da1c5"
            ]
        },
        "0xf7A69C5e5257dEB4e9F190014Fd458711eE4c8aa": {
            "index": 63,
            "amount": "0x68ccf73cd2b434f5bc",
            "proof": [
                "0x2f8edd415bf009db0356d04585845763b314d74f9800b601e3d0923eab629a6f",
                "0xc8a963490279786bf4d9522dad319dd536d7de4764d2fc6564356ff73b49cf16",
                "0x955c47a5eea3ebf139056c0603d096a40a686b2304506f7509859fe9cc19bd79",
                "0x21daac29f18f235ede61e08c609f5762e5d12f87d9f014a3254039eb7b71d931",
                "0x4fcfc1702cc3495bc600779c15a4aec4dc5f6432cbf82d5209c0f07095ffe33c",
                "0x3d159ff1e06840b9a541438da880d6637874661722c48e37343c9e6329245c2e"
            ]
        }
    }
}

*/


pragma solidity 0.8.16;

import "./MerkleProof.sol";

interface ERC20Like {
    function transfer(address dst, uint qty) external returns (bool);
}

contract MerkleDistributor {

    event Claimed(uint256 index, address account, uint256 amount);

    address public immutable token;
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint96 amount, bytes32[] memory merkleProof) external {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(ERC20Like(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

/**
 * @title MerkleProof
 * @dev Merkle proof verification based on
 * https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /**
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images are sorted.
   * @param proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param root Merkle root
   * @param leaf Leaf of Merkle tree
   */
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  )
    internal
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }
}