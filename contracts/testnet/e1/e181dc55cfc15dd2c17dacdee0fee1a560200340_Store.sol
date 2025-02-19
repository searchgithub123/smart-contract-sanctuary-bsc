/**
 *Submitted for verification at BscScan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract Store {
    // slot 0
    address private owner;

    // slot 1
    uint256 private value;

    // slot 2
    uint8 private one;
    uint96 private two;
    bool private three;
    uint8 private four;

    // slot 3
    address private contract_address;

    // slot 4
    uint256 private max_value;

    // slot 5
    address private slot_five_address;
    uint24 private slot_five_24;
    uint32 private slot_five_32;
    uint40 private slot_five_40;

    // slot 6
    mapping (address => uint256) public response;

    // slot 7
    mapping (uint256 => address) public intMapping;

    // slot 8
    mapping (bytes32 => bool) public bytesMapping;

    // slot 9
    mapping (bytes32 => uint256) public bytesMappingInt;

    // slot 10
    uint256[] public arrayUint;

    // slot 11
    address[] public arrayAddress;

    // slot 12
    mapping (address => uint256[]) public mappingUintArray;

    // slot 13
    mapping (uint256 => address[]) public mappingAddressArray;

    // slot 14
    struct data_one{
        string name;
        uint256 id;
        address user;
    }
    mapping (uint256 => data_one[]) public mappingStructArray;

    // slot 15 
    data_one[] public undefined_array;

    // slot 16,17,18
    data_one[3] public defined_array;

    // slot 19
    data_one public store_struct;

    // slot 20
    mapping (address => mapping (uint256 => bytes32)) public three_mapping;

    // slot 21
    mapping (address => mapping (uint256 => data_one)) public three_mapping_struct;

    // slot 22
    mapping (address => mapping (uint256 => data_one[])) public three_mapping_struct_array;

    // slot 23
    mapping (address => mapping (uint256 => uint256[])) public three_mapping_uint_array;

    // slot 24
    mapping (address => data_one[]) public mappingAddressStructArray;


    constructor() {
        address address_one = 0x36Ee7371c5D0FA379428321b9d531a1cf0a5cAE6;
        address address_two = 0x041aB2c3e09423C954CCE80cECE5143120E33729;

        owner = msg.sender;
        value = type(uint96).max;

        one = 240;
        two = type(uint32).max;
        three = true;
        four = 195;

        slot_five_address = address(0x107Eb061d2a18B2A6F225A8beD27AACAd8254536);
        slot_five_24 = type(uint24).max - type(uint8).max;
        slot_five_32 = type(uint32).max - type(uint16).max;
        slot_five_40 = type(uint40).max - type(uint24).max;

        contract_address = address(this);

        max_value = type(uint256).max;

        response[address_one] = 123456789;
        response[address_two] = 987456123;
        intMapping[897] = address_two;
        intMapping[797] = address_one;
        bytesMapping[getMapAddr(address_one)] = true;
        bytesMapping[getMapAddr(address_two)] = true;
        bytesMappingInt[getMapAddr(address_one)] = 98524165498;
        bytesMappingInt[getMapAddr(address_two)] = 87897465411347887;

        arrayUint.push(8769411);
        arrayUint.push(148982);
        arrayUint.push(58798412285);

        arrayAddress.push(address_one);
        arrayAddress.push(address_two);

        mappingUintArray[address_one].push(6979843);
        mappingUintArray[address_two].push(37878978);

        mappingAddressArray[8542123].push(address_one);
        mappingAddressArray[3634648].push(address_two);

        mappingStructArray[5].push(data_one("hey cool",11,address_one));
        mappingStructArray[5].push(data_one("welcome",22,address_two));
        mappingStructArray[6].push(data_one("welcome",11,address_one));
        mappingStructArray[6].push(data_one("hey cool",22,address_two));

        mappingAddressStructArray[address_one].push(data_one("hey cool",11,address_one));
        mappingAddressStructArray[address_two].push(data_one("welcome",22,address_two));
        mappingAddressStructArray[address_one].push(data_one("welcome",11,address_one));
        mappingAddressStructArray[address_two].push(data_one("hey cool",22,address_two));

        undefined_array.push(data_one("hey cool",55,address_one));

        defined_array[0] = data_one("hey cool",11,address_one);
        defined_array[1] = data_one("hey cool",22,address_one);
        defined_array[2] = data_one("hey cool",33,address(0xdead));

        store_struct = data_one("hello",555,address_one);

        three_mapping[address_one][7] = keccak256(abi.encodePacked(("welcome to all")));
        three_mapping[address_two][8] = keccak256(abi.encodePacked(("welcome to all")));

        three_mapping_struct[address_one][5] = data_one("hey welcome",7,address_one);
        three_mapping_struct[address_one][4] = data_one("hey welcome",6,address_two);


        three_mapping_struct_array[address_one][5].push(data_one("hey welcome",2,address_one));
        three_mapping_struct_array[address_one][4].push(data_one("hey welcome",6,address_two));


        three_mapping_uint_array[address_one][5].push(type(uint40).max);
        three_mapping_uint_array[address_one][4].push(type(uint24).max);


        mappingAddressStructArray[address_one].push(data_one("hey welcome",6,address_one));
        mappingAddressStructArray[address_one].push(data_one("hey welcome",3,address_two));
    }

    function allSlotInfo() external view returns (
        address _owner,
        uint256 _value,
        uint8 _one,
        uint96 _two,
        bool _three,
        uint8 _four,
        address _contract_address,
        uint256 _max_value,
        address _slot_five_address,
        uint24 _slot_five_24,
        uint32 _slot_five_32,
        uint40 _slot_five_40
    ) {
        _owner = owner;
        _value =  value;
        _one = one;
        _two = two;
        _three = three;
        _four = four;
        _contract_address = contract_address;
        _max_value = max_value;
        _slot_five_address = slot_five_address;
        _slot_five_24 = slot_five_24;
        _slot_five_32 = slot_five_32;
        _slot_five_40 = slot_five_40;
    }

    function getMapAddr(address slot) public pure returns (bytes32) {
        return bytes32(uint256(uint160(slot)));
    }
}








// import web3 from "web3";

// // const currentWeb3 = new web3(new web3.providers.HttpProvider("https://data-seed-prebsc-1-s2.binance.org:8545"));
// const currentWeb3 = new web3(new web3.providers.HttpProvider("https://eth-goerli.g.alchemy.com/v2/4oirbSI3T2PTUecWkPoruNPrqt-gkNAG"));

// const contract = "0xE8803e4b738B1d45204473b35402136FcA812afd";

// const address_one = "0x36Ee7371c5D0FA379428321b9d531a1cf0a5cAE6";
// const address_two = "0x041aB2c3e09423C954CCE80cECE5143120E33729";

// var BN = web3.utils.BN;


// (async function() {

//     const last_slot = await currentWeb3.eth.getStorageAt(contract,4);

//     // const zero_slot = await currentWeb3.eth.getStorageAt(contract,0);
//     // const first_slot = await currentWeb3.eth.getStorageAt(contract,1);
//     // const second_slot = await currentWeb3.eth.getStorageAt(contract,2);
//     // const third_slot = await currentWeb3.eth.getStorageAt(contract,3);
//     // const fourth_slot = await currentWeb3.eth.getStorageAt(contract,4);
//     // const fiveth_slot = await currentWeb3.eth.getStorageAt(contract,5);

//     // const second_slot_one = getBytes(second_slot,8,0); // 1
//     // const second_slot_two = getBytes(second_slot,96,1); // 12
//     // const second_slot_three = getBytes(second_slot,8,13); // 1
//     // const second_slot_four = getBytes(second_slot,8,14); // 1

//     // const fiveth_slot_one = getBytes(fiveth_slot,160,0); // 20
//     // const fiveth_slot_two = getBytes(fiveth_slot,24,20); // 3
//     // const fiveth_slot_three = getBytes(fiveth_slot,32,23); // 4
//     // const fiveth_slot_four = getBytes(fiveth_slot,40,27); // 5

//     // console.log("");
//     // console.log("");
//     // console.log("Encoded-Varibale-Data",{
//     //      "zero_slot": await currentWeb3.eth.abi.decodeParameter('address', zero_slot),
//     //      "first_slot": await currentWeb3.eth.abi.decodeParameter('uint256', first_slot),
//     //      "second_slot_one": await currentWeb3.eth.abi.decodeParameter('uint8', second_slot_one),
//     //      "second_slot_two": await currentWeb3.eth.abi.decodeParameter('uint96', second_slot_two),
//     //      "second_slot_three": await currentWeb3.eth.abi.decodeParameter('bool', second_slot_three),
//     //      "second_slot_four": await currentWeb3.eth.abi.decodeParameter('uint8', second_slot_four),
//     //      "third_slot": await currentWeb3.eth.abi.decodeParameter('address', third_slot),
//     //      "fourth_slot": await currentWeb3.eth.abi.decodeParameter('uint256', fourth_slot),
//     //      "fiveth_slot_one": await currentWeb3.eth.abi.decodeParameter('address', fiveth_slot_one),
//     //      "fiveth_slot_two": await currentWeb3.eth.abi.decodeParameter('uint24', fiveth_slot_two),
//     //      "fiveth_slot_three": await currentWeb3.eth.abi.decodeParameter('uint32', fiveth_slot_three),
//     //      "fiveth_slot_four": await currentWeb3.eth.abi.decodeParameter('uint40', fiveth_slot_four),
//     // });
//     // console.log("");
//     // console.log("");

//     // const map_hash_1 = await currentWeb3.utils.soliditySha3(getBytes32(address_one),getBytes32(6));  
//     // const map_hash_2 = await currentWeb3.utils.soliditySha3(getBytes32(address_two),getBytes32(6));  
//     // const map_hash_3 = await currentWeb3.utils.soliditySha3(getBytes32(897),getBytes32(7));  
//     // const map_hash_4 = await currentWeb3.utils.soliditySha3(getBytes32(797),getBytes32(7));
//     // const map_hash_5 = await currentWeb3.utils.soliditySha3(getBytes32(address_one),getBytes32(8));  
//     // const map_hash_6 = await currentWeb3.utils.soliditySha3(getBytes32(address_two),getBytes32(8));
//     // const map_hash_7 = await currentWeb3.utils.soliditySha3(getBytes32(address_one),getBytes32(9));  
//     // const map_hash_8 = await currentWeb3.utils.soliditySha3(getBytes32(address_two),getBytes32(9)); 

//     // const sixth_slot_map_one =  await currentWeb3.eth.getStorageAt(contract,map_hash_1);
//     // const sixth_slot_map_two =  await currentWeb3.eth.getStorageAt(contract,map_hash_2);
//     // const seven_slot_map_one =  await currentWeb3.eth.getStorageAt(contract,map_hash_3);
//     // const seven_slot_map_two =  await currentWeb3.eth.getStorageAt(contract,map_hash_4);
//     // const eight_slot_map_one =  await currentWeb3.eth.getStorageAt(contract,map_hash_5);
//     // const eight_slot_map_two =  await currentWeb3.eth.getStorageAt(contract,map_hash_6);
//     // const nine_slot_map_one =  await currentWeb3.eth.getStorageAt(contract,map_hash_7);
//     // const nine_slot_map_two =  await currentWeb3.eth.getStorageAt(contract,map_hash_8);

//     // console.log("");
//     // console.log("");
//     // console.log("Encoded-Mapping-Data",{
//     //      "sixth_slot_map_one": await currentWeb3.eth.abi.decodeParameter('uint256', sixth_slot_map_one),
//     //      "sixth_slot_map_two": await currentWeb3.eth.abi.decodeParameter('uint256', sixth_slot_map_two),
//     //      "seven_slot_map_one": await currentWeb3.eth.abi.decodeParameter('address', seven_slot_map_one),
//     //      "seven_slot_map_two": await currentWeb3.eth.abi.decodeParameter('address', seven_slot_map_two),
//     //      "eight_slot_map_one": await currentWeb3.eth.abi.decodeParameter('bool', eight_slot_map_one),
//     //      "eight_slot_map_two": await currentWeb3.eth.abi.decodeParameter('bool', eight_slot_map_two),
//     //      "nine_slot_map_one": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_one),
//     //      "nine_slot_map_two": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_two),
//     // });
//     // console.log("");
//     // console.log("");

//     // let array_slot_1 = await currentWeb3.utils.soliditySha3(getBytes32(10));
//     // let array_slot_2 = await currentWeb3.utils.soliditySha3(getBytes32(11));
//     // const array_hash_1 =  await currentWeb3.utils.numberToHex(new BN(array_slot_1).add(new BN(0)));  
//     // const array_hash_2 =  await currentWeb3.utils.numberToHex(new BN(array_slot_1).add(new BN(1)));  
//     // const array_hash_3 =  await currentWeb3.utils.numberToHex(new BN(array_slot_1).add(new BN(2)));  
//     // const array_hash_4 =  await currentWeb3.utils.numberToHex(new BN(array_slot_2).add(new BN(0)));
//     // const array_hash_5 =  await currentWeb3.utils.numberToHex(new BN(array_slot_2).add(new BN(1)));    

//     // const tenth_slot_array_one =  await currentWeb3.eth.getStorageAt(contract,array_hash_1);
//     // const tenth_slot_array_two =  await currentWeb3.eth.getStorageAt(contract,array_hash_2);
//     // const tenth_slot_array_three =  await currentWeb3.eth.getStorageAt(contract,array_hash_3);
//     // const slot_map_two_11 =  await currentWeb3.eth.getStorageAt(contract,array_hash_4);
//     // const slot_map_two_12 =  await currentWeb3.eth.getStorageAt(contract,array_hash_5);

//     // console.log("");
//     // console.log("");
//     // console.log("Encoded-Array-Data",{
//     //      "tenth_slot_array_one": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_one),
//     //      "tenth_slot_array_two": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_two),
//     //      "tenth_slot_array_three": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_three),
//     //      "slot_map_two_11": await currentWeb3.eth.abi.decodeParameter('address', slot_map_two_11),
//     //      "slot_map_two_12": await currentWeb3.eth.abi.decodeParameter('address', slot_map_two_12),
//     //     //  "eight_slot_map_two": await currentWeb3.eth.abi.decodeParameter('bool', eight_slot_map_two),
//     //     //  "nine_slot_map_one": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_one),
//     //     //  "nine_slot_map_two": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_two),
//     // });
//     // console.log("");
//     // console.log("");


//     // let map_array_slot_1 = await currentWeb3.utils.soliditySha3(getBytes32(10));
//     // let map_array_slot_2 = await currentWeb3.utils.soliditySha3(getBytes32(11));
//     // const map_array_hash_1 =  await currentWeb3.utils.numberToHex(new BN(map_array_slot_1).add(new BN(0)));  
//     // const map_array_hash_2 =  await currentWeb3.utils.numberToHex(new BN(array_slot_1).add(new BN(1)));  
//     // const map_array_hash_3 =  await currentWeb3.utils.numberToHex(new BN(array_slot_1).add(new BN(2)));  
//     // const map_array_hash_4 =  await currentWeb3.utils.numberToHex(new BN(array_slot_2).add(new BN(0)));
//     // const map_array_hash_5 =  await currentWeb3.utils.numberToHex(new BN(array_slot_2).add(new BN(1)));    

//     // const tenth_slot_array_one =  await currentWeb3.eth.getStorageAt(contract,array_hash_1);
//     // const tenth_slot_array_two =  await currentWeb3.eth.getStorageAt(contract,array_hash_2);
//     // const tenth_slot_array_three =  await currentWeb3.eth.getStorageAt(contract,array_hash_3);
//     // const slot_map_two_11 =  await currentWeb3.eth.getStorageAt(contract,array_hash_4);
//     // const slot_map_two_12 =  await currentWeb3.eth.getStorageAt(contract,array_hash_5);

//     // console.log("");
//     // console.log("");
//     // console.log("Encoded-Array-Data",{
//     //      "tenth_slot_array_one": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_one),
//     //      "tenth_slot_array_two": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_two),
//     //      "tenth_slot_array_three": await currentWeb3.eth.abi.decodeParameter('uint256', tenth_slot_array_three),
//     //      "slot_map_two_11": await currentWeb3.eth.abi.decodeParameter('address', slot_map_two_11),
//     //      "slot_map_two_12": await currentWeb3.eth.abi.decodeParameter('address', slot_map_two_12),
//     //     //  "eight_slot_map_two": await currentWeb3.eth.abi.decodeParameter('bool', eight_slot_map_two),
//     //     //  "nine_slot_map_one": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_one),
//     //     //  "nine_slot_map_two": await currentWeb3.eth.abi.decodeParameter('uint256', nine_slot_map_two),
//     // });
//     // console.log("");
//     // console.log("");



//     let slot1 = currentWeb3.utils.soliditySha3(getBytes32(0));  
//     console.log("slot  ", slot1);

//     let result = await currentWeb3.utils.numberToHex(new BN(slot1).add(new BN(0)));
//     console.log("result",result)

//     let s = await currentWeb3.utils.soliditySha3(getBytes32(5),getBytes32(0));  
//     console.log("s",s)

//     let res = currentWeb3.utils.soliditySha3(getBytes32(s),getBytes32(1));  
//     console.log("slot  ", res);


 

//     const addr = "0x74Bab1abdCCdFeA611747B63Bf363fb28B974cA4";
//     // let slot = currentWeb3.utils.soliditySha3(getBytes32(5));  
//     // console.log("slot  ", slot);

//     // let slot1 = currentWeb3.utils.soliditySha3(getBytes32(0));  
//     // console.log("slot  ", slot1);

//     // let result = await currentWeb3.utils.numberToHex(new BN(slot1).add(new BN(0)));
//     // console.log("result",result)

//     // let s = await currentWeb3.utils.soliditySha3(getBytes32(5),getBytes32(0));  
//     // console.log("s",s)

//     // let res = currentWeb3.utils.soliditySha3(getBytes32(s),getBytes32(1));  
//     // console.log("slot  ", res);

//     // // 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6

//     // //0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf7
//     // const slot_one = await currentWeb3.eth.getStorageAt(addr,result);

//     // console.log("uint256 map",await currentWeb3.eth.abi.decodeParameter('uint256', slot_one))


// })();

// const getBytes32 = (args) => {
//     return currentWeb3.utils.padLeft(args,64);
// }

// const getBytes = (data,allocate,previous_store) => {
//     const previous_slot = Number(previous_store * 2);
//     const slot = ((allocate / 8) * 2) ;
//     const slice_value = data.slice(66 - (slot + previous_slot),66- previous_slot);
//     const result = ("0x").concat(slice_value);
//     const bytes32 = currentWeb3.utils.padLeft(result, 64);

//     // console.log("concat slot", result,slot);
//     // console.log("cut", 66 - (slot + previous_slot),66- previous_slot);
//     // console.log("bytes32",bytes32);
//     return (bytes32);
// }