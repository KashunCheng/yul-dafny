/*
 * Copyright 2023 Franck Cassez
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License. You may obtain
 * a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software dis-
 * tributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

include "../../../libs/evm-dafny/src/dafny/util/int.dfy"
include "../../../libs/evm-dafny/src/dafny/core/memory.dfy"
include "../../../libs/evm-dafny/src/dafny/bytecode.dfy"


/**
  * Provide Semantics of Yul builtin operators/functions.
  *
  * EVM dialect.
  * @link{https://docs.soliditylang.org/en/latest/yul.html#evm-dialect}
  */
module Yul {

  import opened Int
  import Memory
  import Bytecode
  import Word

  //  Arithmetic operators.

  /**
    *   Addition modulo 2^256.
    *   @param      x    
    *   @param      y
    *   @returns    x + y mod 2^256.
    */
  function Add(x: u256, y: u256): u256
  {
    ((x as nat + y as nat) % TWO_256) as u256
  }

  /**
    *   Subtraction modulo 2^256.
    *   @param      x    
    *   @param      y
    *   @returns    x as int - y as int mod 2^256.
    */
  function Sub(x: u256, y: u256): u256
  {
    ((x as int - y as int) % TWO_256) as u256
  }

  /**
    *   Multiplication modulo 2^256.
    *   @param      x    
    *   @param      y
    *   @returns    x * y mod 2^256.
    */
  function Mul(x: u256, y: u256): u256
    ensures x as nat * y as nat < TWO_256 ==> Mul(x, y) == x * y
  {
    ((x as nat * y as nat) % TWO_256) as u256
  }

  /**
    *   Division modulo 2^256.
    *   @param      x    
    *   @param      y
    *   @returns    if y !=0 then x / y mod 2^256 else 0.
    *   @note       Re-use helpers in the bytecode semantics.
    */
  function Div(x: u256, y: u256): u256
    ensures y != 0  ==> Div(x, y) == x / y
  {
    Bytecode.DivWithZero(x, y)
  }

  /**
    *   Signed integer Division modulo 2^256.
    *   @param      x    
    *   @param      y
    *   @returns    if y !=0 then x / y for signed numbers (2-s complement) mod 2^256 else 0.
    *   @note       We assume that the semantics in Yul is the same as in the EVM dialect. 
    *               Use the EVM bytecode helpers.
    */
  function SDiv(x: u256, y: u256): u256
    // ensures y > 0 && x > 0 ==> SDiv(x, y) == x / y
  {
    var lhs := Word.asI256(x);
    var rhs := Word.asI256(y);
    var res := Word.fromI256(Bytecode.SDivWithZero(lhs, rhs));
    res
  }

  /**
    *   Modulo with zero handling.
    *   @param      x    
    *   @param      y
    *   @returns    if y !=0 then x % y else 0.
    */
  function Mod(x: u256, y: u256) : u256
    ensures y != 0 ==> Mod(x, y) == x % y
  {
    if y == 0 then 0 as u256
    else
      (x % y) as u256
  }

  /**
    *   Signed Modulo with zero handling.
    *   @param      x    
    *   @param      y
    *   @returns    if y !=0 then x % y else 0.
    */
  function SModWithZero(x: u256, y: u256) : u256
  {
    var lhs := Word.asI256(x);
    var rhs := Word.asI256(y);
    var res := Word.fromI256(Bytecode.SModWithZero(lhs, rhs));
    res
  }

  /**
    *   Signed Modulo with zero handling.
    *   @param      x    
    *   @param      y
    *   @returns    if y !=0 then x % y else 0.
    */
  function Exp(x: u256, y: u256) : u256
  {
    (MathUtils.Pow(x as nat, y as nat) % TWO_256) as u256
  }

  //  Comparison operators.

  /**
    *   Unsigned lower than.
    *   @param      x   
    *   @param      y 
    *   @returns    1 if x < y and 0 otherwise.
    */
  function lt(x: u256, y: u256): (r: u256)
    ensures r > 0 <==> x < y
    ensures r == 0 <==> x >= y
  {
    if x < y then 1 else 0
  }

  /**
    *   Unsigned greater than.
    *   @param      x   
    *   @param      y 
    *   @returns    1 if x < y and 0 otherwise.
    */
  function Gt(x: u256, y: u256): (r: u256)
    ensures r > 0 <==> x > y
    ensures r == 0 <==> x <= y
  {
    if x > y then 1 else 0
  }

  /**
    *   Signed lower than.
    *   @param      x   
    *   @param      y 
    *   @returns    1 if x as int < y as int and 0 otherwise.
    */
  function SLt(x: u256, y: u256): (r: u256)
  {
    var lhs := Word.asI256(x);
    var rhs := Word.asI256(y);
    if lhs < rhs then 1 else 0
  }

  /**
    *   Signed greater than.
    *   @param      x   
    *   @param      y 
    *   @returns    1 if x <as int  y as int and 0 otherwise.
    */
  function SGt(x: u256, y: u256): (r: u256)
  {
    var lhs := Word.asI256(x);
    var rhs := Word.asI256(y);
    if lhs > rhs then 1 else 0
  }

  /**
    *   Equality.
    *   @param      x   
    *   @param      y 
    *   @returns    1 if x == y and 0 otherwise.
    */
  function Eq(x: u256, y: u256): (r: u256)
  {
    if x == y then 1 else 0
  }

  /**
    *   Is zero.
    *   @param      x   
    *   @returns    1 if x == 0 and 0 otherwise.
    */
  function IsZero(x: u256): (r: u256)
  {
    if x == 0 then 1 else 0
  }

  //    Bitwise operators

  /**
    *   Bitwise not
    *   @param      x    
    *   @returns    not(x), every bit is flipped.
    */
  function Not(x: u256) : u256
  {
    (TWO_256 - 1 - x as nat) as u256
  }

  /**
    *   Bitwise And
    *   @param      x    
    *   @param      y    
    *   @returns    x && y
    */
  function And(x: u256, y: u256) : u256
  {
    x 
  }

  //  Memory operators.

  /**
    *   Memory store. Store a u256 into memory.
    *
    *   @param      address The start address.
    *   @param      value   Value to store.
    *   @param      m       The memory before store operation.
    *   @returns    m[address..address + 31] <- value.
    *
    *   @note       Memory is a word-addressable array of bytes. A u256 value
    *               is stored into 32 bytes ranging from address to address + 31.
    *     
    */
  function mstore(address: u256, value: u256, m: Memory.T): (m' :Memory.T)
    requires Memory.Size(m) % 32 == 0
    ensures Memory.Size(m') % 32 == 0
    ensures Memory.Size(m') >= address as nat + 32
  {
    //  Make sure memory is large enough.
    var m' := Memory.ExpandMem(m, address as nat, 32);
    Memory.WriteUint256(m', address as nat, value)
  }


}