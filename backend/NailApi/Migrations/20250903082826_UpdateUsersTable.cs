using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NailApi.Migrations
{
    /// <inheritdoc />
    public partial class UpdateUsersTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DatabaseName",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "DatabaseUser",
                table: "Users",
                newName: "UserLogin");

            migrationBuilder.RenameColumn(
                name: "DatabasePassword",
                table: "Users",
                newName: "PasswordLogin");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UserLogin",
                table: "Users",
                newName: "DatabaseUser");

            migrationBuilder.RenameColumn(
                name: "PasswordLogin",
                table: "Users",
                newName: "DatabasePassword");

            migrationBuilder.AddColumn<string>(
                name: "DatabaseName",
                table: "Users",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }
    }
}
